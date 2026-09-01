# frozen_string_literal: true

module Reports
  # Peer-review report: returns raw review rows (reviewer, reviewee, responses,
  # scores) plus computed score percentages per reviewer and per-team averages.
  #
  # Three data sources:
  #
  #   Review rows — loads all ReviewResponseMaps for the assignment with reviewer,
  #     reviewee, responses, and scores eagerly loaded, then serializes via as_json.
  #
  #   ScoresReducer — streams ReviewResponseMap rows for the assignment. For each
  #     map, picks the latest submitted response per round (via
  #     latest_submitted_response_by_round) and computes a score percentage from
  #     the response's answers relative to the questionnaire's max score.
  #     Output: { reviewer_id => { reviewee_id => { round => score_pct } } }
  #
  #   AvgRangesReducer — streams AssignmentTeam rows. For each team, the average
  #     review score is computed from its eagerly-loaded review_mappings and their
  #     nested responses and scores (via aggregate_review_grade).
  #     Output: { team_id => avg_score }
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

    def run
      maps = ReviewResponseMap
               .for_assignment(@reportable.id)
               .includes(reviewer: :user, reviewee: :user, responses: { scores: :item })

      {
        reviews:          maps.as_json(MAP_JSON_OPTIONS),
        reviewer_scores:  ScoresReducer.new(@reportable).run,
        team_averages:    AvgRangesReducer.new(@reportable).run
      }
    end

    # -----------------------------------------------------------------------
    # Reducer 1 — per-reviewer × reviewee × round score percentages.
    # Streams ReviewResponseMap rows with responses and scores eagerly loaded.
    # For each map, delegates to latest_submitted_response_by_round to pick
    # the most recent submitted response per round without N+1 queries.
    # Output: { reviewer_id => { reviewee_id => { round => score_pct } } }
    # -----------------------------------------------------------------------
    class ScoresReducer < BaseReducer
      def source
        ReviewResponseMap
          .for_assignment(@reportable.id)
          .includes(responses: { scores: :item })
      end

      def initial_state
        Hash.new do |state, reviewer_id|
          state[reviewer_id] = Hash.new { |by_reviewee, reviewee_id| by_reviewee[reviewee_id] = {} }
        end
      end

      def accumulate(state, map)
        map.latest_submitted_response_by_round.each do |round, response|
          next if response.maximum_score.zero?

          score_pct = (response.aggregate_questionnaire_score.to_f / response.maximum_score * 100).round(2)
          state[map.reviewer_id][map.reviewee_id][round] = score_pct
        end
      end
    end

    # -----------------------------------------------------------------------
    # Reducer 2 — per-team average review score.
    # Streams AssignmentTeam rows with review_mappings, responses, and scores
    # eagerly loaded to avoid N+1. Delegates score computation to
    # aggregate_review_grade which picks the latest submitted response per
    # round per map and normalizes the score.
    # Output: { team_id => avg_score }
    # -----------------------------------------------------------------------
    class AvgRangesReducer < BaseReducer
      def source
        AssignmentTeam
          .where(parent_id: @reportable.id)
          .includes(review_mappings: { responses: { scores: :item } })
      end

      def initial_state = {}

      def accumulate(state, team)
        state[team.id] = team.aggregate_review_grade
      end
    end
  end
end