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

  # returns the assignment related to the response map
  def response_assignment
    Participant.find(reviewer_id).assignment
  end

  def needs_update_link?
    # Get the most recent response for this map
    last = Response.where(map_id: id).order(Arel.sql('created_at DESC')).first

    # If there’s no previous response, it’s clearly a new review
    return true if last.nil?

    last_created_at = last.created_at

    # ---- Condition 1: Reviewee made a newer submission after the last review ----
    if reviewee.respond_to?(:latest_submission_at) &&
       reviewee.latest_submission_at.present? &&
       reviewee.latest_submission_at > last_created_at
      return true
    end

    # ---- Condition 2: Current round advanced since the last review ----
    if respond_to?(:current_round)
      last_round = (last.respond_to?(:round) ? last.round : 0).to_i
      curr_round = current_round.to_i
      return true if curr_round > last_round
    end

    # Otherwise, keep "Edit"
    false
  end

  def self.assessments_for(team)
    responses = []
    # stime = Time.now
    if team
      array_sort = []
      sort_to = []
      maps = where(reviewee_id: team.id)
      maps.each do |map|
        next if map.response.empty?

        all_resp = Response.where(map_id: map.map_id).last
        if map.type.eql?('ReviewResponseMap')
          # If its ReviewResponseMap then only consider those response which are submitted.
          array_sort << all_resp if all_resp.is_submitted
        else
          array_sort << all_resp
        end
        # sort all versions in descending order and get the latest one.
        sort_to = array_sort.sort # { |m1, m2| (m1.updated_at and m2.updated_at) ? m2.updated_at <=> m1.updated_at : (m1.version_num ? -1 : 1) }
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

  # Safely read the team's latest submission time if the API exists on Participant.
  def latest_submission_at_for_reviewee
    return nil unless reviewee.respond_to?(:latest_submission_at)

    reviewee.latest_submission_at
  end

  # Safely read "current round".
  # Prefer assignment.current_round if present; fall back to any method on self; else 0.
  def current_round_safely
    if assignment && assignment.respond_to?(:current_round)
      assignment.current_round
    elsif respond_to?(:current_round)
      current_round
    else
      0
    end
  end
end
