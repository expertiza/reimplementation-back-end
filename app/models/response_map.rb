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
    # If nothing has been reviewed yet → start a new review
    return true if response.empty? # NOTE: your assoc is singular `:response`

    last = Response.where(map_id: map_id)
                   .order(Arel.sql('COALESCE(submitted_at, created_at) DESC'))
                   .first

    # Strategy 1: Round-based (for each round, a new review is needed)
    if respond_to?(:current_round) && last.respond_to?(:round) && current_round && (last.round.to_i < current_round.to_i)
      return true
    end

    # Strategy 2: Artifact/time-based (if its a new submission, a new review is needed)
    if reviewee.respond_to?(:latest_submission_at) && last
      last_review_time = last.submitted_at || last.created_at
      return true if reviewee.latest_submission_at && last_review_time &&
                     reviewee.latest_submission_at.to_i > last_review_time.to_i
    end

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
end
