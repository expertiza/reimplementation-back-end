# frozen_string_literal: true

class ResponseMap < ApplicationRecord
  has_many :responses, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  alias map_id id

  # Shared helper for Response#rubric_label; looks up the declarative constant so each map advertises its UI label
  def response_map_label
    const_name = "#{self.class.name.demodulize.underscore.upcase}_TITLE"
    if ResponseMapSubclassTitles.const_defined?(const_name)
      ResponseMapSubclassTitles.const_get(const_name).presence
    end
  end

  def questionnaire
    Questionnaire.find_by(id: reviewed_object_id)
  end

  # Returns the assignment context for this map, derived from the reviewer participant.
  def reviewer_assignment
    reviewer&.assignment
  end

  # Backward-compatible alias used by older call sites.
  def response_assignment
    reviewer_assignment
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
    last_round = (response_exposes_round?(last) ? last.round : 0).to_i
    curr_round = current_round_from_due_dates.to_i
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
    candidates << reviewee.updated_at if record_has_updated_timestamp?(reviewee)

    # Check team-related timestamps if the reviewee has a team
    if reviewee_exposes_team?(reviewee)
      team = reviewee.team
      candidates << team.updated_at if record_has_updated_timestamp?(team)

      # Also gather timestamps from join records (teams_participants) so collaborator edits count as activity
      if team_exposes_memberships?(team)
        team.teams_participants.each do |tp|
          candidates << tp.updated_at if record_has_updated_timestamp?(tp)
        end
      end
    end

    candidates.compact.max
  end

  # Infer the current review round from due dates when the assignment doesn’t provide it directly.
  def current_round_from_due_dates
    return 0 unless assignment

    # Gather all due dates with round and due_at

    due_dates = Array(assignment.due_dates).select { |due_date| due_date_has_round_and_due_at?(due_date) }
    return 0 if due_dates.empty?

    # Find the latest due date that is in the past (or the earliest if none are in the past)
    past = due_dates.select { |d| d.due_at <= Time.current }

    # Use the latest past due date if available, otherwise the earliest future due date
    reference =
      if past.any?
        past.sort_by(&:due_at).last
      else
        due_dates.sort_by(&:due_at).first
      end
    reference.round.to_i
  end

  private

  # Older subclasses can omit this reader, so guard before accessing it.
  def response_exposes_round?(response)
    response.respond_to?(:round, true)
  end

  # Some legacy records may not expose updated_at.
  def record_has_updated_timestamp?(record)
    record.respond_to?(:updated_at) && record.updated_at.present?
  end

  def reviewee_exposes_team?(reviewee_record)
    reviewee_record.respond_to?(:team) && reviewee_record.team.present?
  end

  def team_exposes_memberships?(team_record)
    team_record.respond_to?(:teams_participants)
  end

  def due_date_has_round_and_due_at?(due_date)
    due_date.respond_to?(:round) && due_date.round.present? &&
      due_date.respond_to?(:due_at) && due_date.due_at.present?
  end
end
