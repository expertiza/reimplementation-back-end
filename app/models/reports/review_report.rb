# frozen_string_literal: true

module Reports
  # Peer-review report: one eager-loaded query shared across all metrics.
  #
  # Output:
  #   {
  #     reviews: [
  #       {
  #         id: Integer,                         # ReviewResponseMap id
  #         reviewer: {
  #           id: Integer,                       # AssignmentParticipant id
  #           user: { id: Integer, name: String }
  #         },
  #         reviewee: { id: Integer },           # AssignmentTeam id
  #         responses: [
  #           {
  #             id: Integer,
  #             round: Integer,                  # review round number (1-based)
  #             is_submitted: Boolean,
  #             additional_comment: String,
  #             scores: [
  #               {
  #                 id: Integer,
  #                 answer: Integer,             # raw score value
  #                 comments: String,
  #                 item: { id: Integer, txt: String, weight: Integer }
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     ],
  #     reviewer_scores: {
  #       reviewer_id => {
  #         reviewee_id => {
  #           round => Float   # score as a percentage (0–100)
  #         }
  #       }
  #     },
  #     team_averages: {
  #       team_id => Float     # average review score across all reviewers, as a percentage (0–100)
  #     }
  #   }
  class ReviewReport
    # Whitelist for as_json — includes only fields the frontend needs,
    # excluding internal columns (raw FKs, timestamps, STI type, etc.).
    MAP_JSON_OPTIONS = {
      only: [:id],
      include: {
        reviewer: {
          only: [:id],
          include: { user: { only: %i[id name] } }
        },
        reviewee: {
          only: [:id],
          include: { user: { only: %i[id name] } }
        },
        responses: {
          only: %i[id round additional_comment is_submitted],
          include: {
            scores: {
              only: %i[id answer comments],
              include: { item: { only: %i[id txt weight] } }
            }
          }
        }
      }
    }.freeze

    def self.for_assignment(assignment)
      new(assignment)
    end

    def initialize(reportable)
      @reportable = reportable
    end

    # Example (2 reviewers, 1 team, 1 round):
    #   report = ReviewReport.for_assignment(assignment).run
    #   report[:reviewer_scores]
    #   # => { 7 => { 3 => { 1 => 87.5 } } }   # reviewer 7 gave team 3 an 87.5% in round 1
    #   report[:team_averages]
    #   # => { 3 => 84.0 }                       # team 3's average across all reviewers
    def run
      # Single eager-load query shared by all downstream computation.
      maps = ReviewResponseMap
               .for_assignment(@reportable.id)
               .includes(reviewer: :user, reviewee: :user, responses: { scores: :item })

      # Precompute max_question_score per round once to avoid N+1 inside
      # maximum_score → questionnaire → assignment_questionnaires.find_by.
      max_q_score_by_round = questionnaire_max_score_by_round

      reviewer_scores, team_averages, reviewer_volumes = compute_all_metrics(maps, max_q_score_by_round)

      {
        reviews:                      maps.as_json(MAP_JSON_OPTIONS),
        reviewer_scores:              reviewer_scores,
        reviewer_volumes:             reviewer_volumes,
        team_averages:                team_averages,
        rubric_ranges:                rubric_ranges_by_round,
        reviewer_grades:              reviewer_grades_by_participant(maps),
        instructor_grade_min_score:   @reportable.instructor_grade_min_score,
        instructor_grade_max_score:   @reportable.instructor_grade_max_score
      }
    end

    private

    # Single pass over the pre-loaded maps that produces all three metrics:
    #   reviewer_scores  — { reviewer_id => { reviewee_id => { round => pct } } }
    #   team_averages    — { team_id => { round => { min:, max:, avg: } } }
    #   reviewer_volumes — { reviewer_id => { round => avg_unique_word_count } }
    #
    # Previously these were three separate DB queries (ScoresReducer,
    # VolumeReducer, AvgRangesReducer) each re-loading the same maps and each
    # calling latest_submitted_response_by_round independently.
    def compute_all_metrics(maps, max_q_score_by_round)
      scores    = Hash.new { |h, rid| h[rid] = Hash.new { |h2, eid| h2[eid] = {} } }
      team_buckets = Hash.new { |h, tid| h[tid] = Hash.new { |h2, r| h2[r] = [] } }
      vol_totals   = Hash.new { |h, rid| h[rid] = Hash.new { |h2, r| h2[r] = { words: 0, count: 0 } } }

      maps.each do |map|
        map.latest_submitted_response_by_round.each do |round, response|
          # --- scores & team averages ---
          max_q = max_q_score_by_round[round].to_i
          unless max_q.zero?
            total_weight = response.scores.sum { |s| s.answer.nil? ? 0 : s.item.weight }
            max_score    = total_weight * max_q
            unless max_score.zero?
              score_sum = response.scores.sum { |s| s.answer.nil? ? 0 : s.answer * s.item.weight }
              pct = (score_sum.to_f / max_score * 100).round(2)
              scores[map.reviewer_id][map.reviewee_id][round] = pct
              team_buckets[map.reviewee_id][round] << pct
            end
          end

          # --- volume ---
          text = (response.scores.map { |s| s.comments.presence } + [response.additional_comment.presence])
                   .compact.join(' ')
          unless text.empty?
            # Count distinct words; a dedicated NLP gem (e.g. Lingua) could replace
            # this regex if richer tokenization is needed later.
            unique_words = text.downcase.scan(/\b[a-z']+\b/).uniq.size
            vol_totals[map.reviewer_id][round][:words] += unique_words
            vol_totals[map.reviewer_id][round][:count] += 1
          end
        end
      end

      team_averages = team_buckets.transform_values do |rounds|
        rounds.transform_values do |bucket|
          next { min: nil, max: nil, avg: nil } if bucket.empty?

          { min: bucket.min.round(2), max: bucket.max.round(2), avg: (bucket.sum / bucket.size).round(2) }
        end
      end

      reviewer_volumes = vol_totals.transform_values do |rounds|
        rounds.transform_values { |b| (b[:words].to_f / [b[:count], 1].max).round(0).to_i }
      end

      [scores, team_averages, reviewer_volumes]
    end

    # Returns max_question_score per round using a single query.
    # Eliminates the N+1 from Response#questionnaire being called per response.
    # Output: { round => Integer }
    def questionnaire_max_score_by_round
      @reportable
        .assignment_questionnaires
        .includes(:questionnaire)
        .each_with_object({}) do |aq, h|
          round = aq.used_in_round || 1
          h[round] = aq.questionnaire&.max_question_score.to_i
        end
    end

    # Returns the rubric score bounds per round so the frontend can anchor
    # the metrics axis to the actual rubric range rather than auto-scaling.
    # Output: { round => { min: Integer, max: Integer } }
    def rubric_ranges_by_round
      @reportable
        .assignment_questionnaires
        .includes(:questionnaire)
        .select { |aq| aq.questionnaire&.questionnaire_type == 'ReviewQuestionnaire' }
        .each_with_object({}) do |aq, hash|
          round = aq.used_in_round || 1
          q     = aq.questionnaire
          hash[round] = { min: q.min_question_score, max: q.max_question_score }
        end
    end

    # Returns saved instructor grades for all reviewers in one query.
    # Output: { participant_id => { grade: Float|nil, comment: String|nil } }
    def reviewer_grades_by_participant(maps)
      participant_ids = maps.map(&:reviewer_id).uniq
      ReviewGrade
        .where(participant_id: participant_ids)
        .each_with_object({}) do |rg, hash|
          hash[rg.participant_id] = { grade: rg.grade_for_reviewer, comment: rg.comment_for_reviewer }
        end
    end
  end
end
