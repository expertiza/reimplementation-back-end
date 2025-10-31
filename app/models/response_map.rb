# frozen_string_literal: true

class ResponseMap < ApplicationRecord
  include ResponseMapSubclassTitles

  has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  alias map_id id

  def questionnaire
    Questionnaire.find_by(id: reviewed_object_id)
  end

  def response_assignment
    Participant.find(reviewer_id).assignment
  end

  # Decide whether the reviewer should see an "Update" button (something new to review)
  # or the default "Edit" button (no changes since the last submitted review).
  def needs_update_link?
    # Most recent submitted review for this mapping
    last = Response.where(map_id: id, is_submitted: true).order(Arel.sql('created_at DESC')).first
    return true if last.nil?

    last_created_at = last.created_at

    #  Latest time the reviewee (or their team) made a submission
    latest_submission = latest_submission_at_for_reviewee
    return true if latest_submission.present? && latest_submission > last_created_at

    # Check if a later review round has passed since the last submitted review
    last_round = (last.respond_to?(:round, true) ? last.round : 0).to_i
    curr_round = current_round_safely.to_i
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

  def survey?
    false
  end

  # Best-effort timestamp of when the reviewee (or their team) last touched the work.
  def latest_submission_at_for_reviewee
    return nil unless reviewee

    candidates = []
    candidates << reviewee.updated_at if reviewee.respond_to?(:updated_at) && reviewee.updated_at.present?

    # Check team-related timestamps if the reviewee has a team
    if reviewee.respond_to?(:team) && reviewee.team
      team = reviewee.team
      candidates << team.updated_at if team.respond_to?(:updated_at) && team.updated_at.present?

    # Also check teams_participants or teams_users join records if they exist
      if team.respond_to?(:teams_participants)
        team.teams_participants.each do |tp|
          candidates << tp.updated_at if tp.respond_to?(:updated_at) && tp.updated_at.present?
        end
      end
    # Also check teams_users join records if they exist
      if team.respond_to?(:teams_users)
        team.teams_users.each do |tu|
          candidates << tu.updated_at if tu.respond_to?(:updated_at) && tu.updated_at.present?
        end
      end
    end

    candidates.compact.max
  end

  # Infer the current review round from due dates when the assignment doesn’t provide it directly.
  def current_round_safely
    return 0 unless assignment

    # Gather all due dates with round and due_at

    due_dates = Array(assignment.due_dates).select do |d|
      d.respond_to?(:round) && d.round.present? &&
        d.respond_to?(:due_at) && d.due_at.present?
    end
    return 0 if due_dates.empty?

    # Find the latest due date that is in the past (or the earliest if none are in the past)
    past = due_dates.select { |d| d.due_at <= Time.current }

    # Use the latest past due date if available, otherwise the earliest future due date
    reference = past.max_by(&:due_at) || due_dates.min_by(&:due_at)
    reference.round.to_i
  end
end
