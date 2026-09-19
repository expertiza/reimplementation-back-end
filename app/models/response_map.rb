# frozen_string_literal: true

class ResponseMap < ApplicationRecord
  has_many :responses, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  alias map_id id

  # Returns the latest submitted response per round for this map.
  # Relies on responses being eager-loaded (e.g. via includes) to avoid N+1.
  # Output: { round => response }
  def latest_submitted_response_by_round
    responses
      .select(&:is_submitted)
      .group_by(&:round)
      .transform_values { |rs| rs.max_by(&:id) }
  end

  # Shared helper for Response#rubric_label; looks up the declarative constant so each map advertises its UI label
  def response_map_label
    const_name = "#{self.class.name.demodulize.underscore.upcase}_TITLE"
    if ExpertizaConstants::ResponseMapTitles.const_defined?(const_name)
      ExpertizaConstants::ResponseMapTitles.const_get(const_name).presence
    end
  end

  def questionnaire
    Questionnaire.find_by(id: reviewed_object_id)
  end

  # Returns the assignment that this map's reviewer belongs to.
  def reviewer_assignment
    reviewer&.assignment
  end

  # Backward-compatible alias used by older call sites.
  def response_assignment
    reviewer_assignment
  end

  # Returns true when the submission changed since the last submitted review,
  # or when the review round changed. True means show "Update"; false means show "Edit".
  def has_submission_been_updated?
    # Most recent submitted review for this mapping
    last = Response.where(map_id: id, is_submitted: true).order(Arel.sql('created_at DESC')).first
    return true if last.nil?

    last_created_at = last.created_at

    # Latest time the reviewee (or their team) made a submission
    latest_submission = latest_submission_at_for_reviewee
    return true if latest_submission.present? && latest_submission > last_created_at

    # Check if a later review round has passed since the last submitted review
    last_round = last.round.to_i
    curr_round = current_round.to_i
    return true if curr_round.positive? && curr_round > last_round

    false
  end

  def self.assessments_for(team)
    responses = []
    if team
      array_sort = []
      sort_to = []
      maps = where(reviewee_id: team.id)
      maps.each do |map|
        next if map.response.empty?

        all_resp = Response.where(map_id: map.map_id).last
        if map.type.eql?('ReviewResponseMap')
          array_sort << all_resp if all_resp.is_submitted
        else
          array_sort << all_resp
        end
        sort_to = array_sort.sort
        responses << sort_to[0] unless sort_to[0].nil?
        array_sort.clear
        sort_to.clear
      end
      responses = responses.sort { |a, b| a.map.reviewer.fullname <=> b.map.reviewer.fullname }
    end
    responses
  end

  # Check to see if this response map is a survey. Default is false, and some subclasses will overwrite to true.
  def survey?
    false
  end

  # Computes the normalized score (0–1) for this map, weighted by each round's
  # questionnaire_weight from assignment_questionnaires.
  # Takes the latest submitted response per round, normalizes it (score/max),
  # multiplies by that round's weight, and returns Σ(normalized × weight) / Σ(weight).
  def review_grade
    return nil if responses.empty?

    latest_responses_by_round = responses
                                .group_by(&:round)
                                .transform_values { |resps| resps.max_by(&:updated_at) }

    weighted_score  = 0.0
    total_weight    = 0.0
    submitted_found = false

    latest_responses_by_round.each_value do |response|
      next unless response.is_submitted

      max = response.maximum_score
      next if max.nil? || max.zero?

      aq     = assignment.assignment_questionnaires.find_by(used_in_round: response.round)
      aq   ||= assignment.assignment_questionnaires.find_by(used_in_round: nil)
      weight = aq&.questionnaire_weight&.to_f || 1.0

      submitted_found  = true
      weighted_score  += (response.aggregate_questionnaire_score.to_f / max) * weight
      total_weight    += weight
    end

    return nil unless submitted_found
    return 0 if total_weight.zero?

    weighted_score / total_weight
  end

  # All response map types expose a common aggregate_response_score interface.
  # Subclasses (e.g. QuizResponseMap) may override if their scoring differs.
  alias aggregate_response_score review_grade

  # Averages review_grade across a collection of ResponseMaps.
  # Called by AssignmentTeam#aggregate_reviewer_score and AssignmentParticipant#aggregate_teammate_review_grade.
  def self.compute_average_reviewer_score(maps)
    return nil if maps.blank?

    weighted_sum = 0.0
    total_weight = 0.0

    maps.each do |map|
      grade = map.review_grade
      next if grade.nil?

      weighted_sum += grade
      total_weight += 1.0
    end

    return nil if total_weight.zero?

    (weighted_sum / total_weight * 100).round(2)
  end

  # Best-effort timestamp of when the reviewee (or their team) last touched the work.
  def latest_submission_at_for_reviewee
    return nil unless reviewee

    candidates = []
    candidates << reviewee.updated_at

    # Check team-related timestamps if the reviewee has a team
    if reviewee.team.present?
      team = reviewee.team
      candidates << team.updated_at

      # Also gather timestamps from join records (teams_participants) so collaborator edits count as activity
      team.teams_participants.each do |tp|
        candidates << tp.updated_at
      end
    end

    candidates.compact.max
  end

  # Returns the current review round for this map's assignment.
  def current_round
    DueDate.current_round_number_for(assignment)
  end

  # Reference note:
  # The active implementation uses direct attribute/association access
  # because the current schema and models already guarantee the fields used above:
  # Response has `round` and `updated_at`, Participant has `updated_at` and `team`,
  # Team has `updated_at` and `teams_participants`, and TeamsParticipant has `updated_at`.
  # That makes the defensive `respond_to?` guards unnecessary in the current backend.
  #
  # Kept the older defensive helpers below as commented reference code in case support is
  # needed later for partially migrated objects, alternate subclasses, or compatibility
  # code that may not expose these readers consistently.
  #
  # private
  #
  # # Returns true when a response object exposes the `round` reader used by
  # # `has_submission_been_updated?` while comparing the saved review round.
  # def response_supports_round?(response)
  #   response.respond_to?(:round, true)
  # end
  #
  # # Returns true when a record has a usable `updated_at` timestamp for activity tracking
  # # in `latest_submission_at_for_reviewee`.
  # def record_has_updated_timestamp?(record)
  #   record.respond_to?(:updated_at) && record.updated_at.present?
  # end
  #
  # # Returns true when the reviewee exposes a `team` association and that association is present.
  # # This is related to checking team activity in `latest_submission_at_for_reviewee`.
  # def reviewee_has_team?(reviewee_record)
  #   reviewee_record.respond_to?(:team) && reviewee_record.team.present?
  # end
  #
  # # Returns true when a team exposes the `teams_participants` association used to inspect
  # # collaborator membership timestamps in `latest_submission_at_for_reviewee`.
  # def team_supports_memberships?(team_record)
  #   team_record.respond_to?(:teams_participants)
  # end
end
