# frozen_string_literal: true

class ResponseMap < ApplicationRecord
  include ResponseMapSubclassTitles

  has_many :responses, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  alias map_id id

  # Returns the title used for display - should be overridden by subclasses
  # Default implementation removes "ResponseMap" from the class name
  # @return [String] the display title for this type of response map
  def title
    self.class.name.sub("ResponseMap", "")
  end

  def questionnaire
    Questionnaire.find_by(id: reviewed_object_id)
  end

  # returns the assignment related to the response map
  def response_assignment
    # reviewer will always be the Assignment Participant so finding Assignment based on reviewer_id.
    return reviewer.assignment
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

  # Computes the average score (as a fraction between 0 and 1) across the latest submitted responses
  # from each round for corresponding ResponseMap.
  def aggregate_reviewers_score
    # Return nil if there are no responses for this map
    return nil if responses.empty?

    # Group all responses by round, then select the latest one per round based on the most recent created one (i.e., most recent revision in that round)
    latest_responses_by_round = responses
      .group_by(&:round)
      .transform_values { |resps| resps.max_by(&:updated_at) } 

    response_score = 0.0  # Sum of actual scores obtained
    total_score = 0.0     # Sum of maximum possible scores
    submitted_found = false  #flag to track if any submitted response exists

    # For each latest response in each round, if the response was submitted, sum up its earned score and its maximum possible score.
    latest_responses_by_round.each_value do |response|
      # Only consider responses that were submitted
      next unless response.is_submitted
      
      submitted_found = true  # true if a submitted response is found
      
      # Accumulate the obtained and maximum scores
      response_score += response.aggregate_questionnaire_score
      total_score += response.maximum_score
    end

    # If no submitted responses at all, return nil
    return nil unless submitted_found

    # Return the normalized score (as a float), or 0 if no valid total score
    total_score > 0 ? (response_score.to_f / total_score) : 0
  end

  # Returns the original contributor (typically the reviewee)
  # Can be overridden by subclasses for different contributor types
  # @return [Participant] the participant being reviewed
  def contributor
    self.reviewee
  end

  # Returns the latest response for this map
  # @return [Response, nil] the most recent response or nil if none exist
  def latest_response
    self.responses.order(created_at: :desc).first
  end

  # Checks if this map has any submitted responses
  # @return [Boolean] true if there are any submitted responses
  def has_a_response_submitted?
    self.responses.where(is_submitted: true).exists?
  end

  # Hook for map-type-specific notification side effects after response submission.
  # Subclasses can override this and send emails/notifications as needed.
  # @param _response [Response, nil] recently submitted response
  def send_notification_email(_response = nil)
    nil
  end

  # Return response maps for an assignment
  scope :for_assignment, ->(assignment_id) { where(reviewed_object_id: assignment_id) }

  # Return response maps for a reviewer and eager-load responses
  scope :for_reviewer_with_responses, ->(reviewer_id) { where(reviewer_id: reviewer_id).includes(:responses) }

  # Compute response statistics for an assignment
  def self.response_rate_for_assignment(assignment_id)
    total_maps = for_assignment(assignment_id).count

    completed_maps = for_assignment(assignment_id)
                     .joins(:responses)
                     .where(responses: { is_submitted: true })
                     .distinct
                     .count

    {
      total_response_maps: total_maps,
      completed_response_maps: completed_maps,
      response_rate: total_maps > 0 ? (completed_maps.to_f / total_maps * 100).round(2) : 0
    }
  end
end
