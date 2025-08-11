class ResponseMap < ApplicationRecord
  include ResponseMapSubclassTitles

  has_many :responses, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  alias map_id id

  def questionnaire
    Questionnaire.find_by(id: reviewed_object_id)
  end

  # returns the assignment related to the response map
  def response_assignment
    return Participant.find(self.reviewer_id).assignment
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
  # from each round for this ReviewResponseMap.
  def review_grade 
    # Return 0 if there are no responses for this map
    return 0 if responses.empty?

    # Group all responses by round, then select the latest one per round based on the most recent created one (i.e., most recent revision in that round)
    latest_responses_by_round = responses
      .group_by(&:round)
      .transform_values { |resps| resps.max_by(&:created_at) } 

    response_score = 0.0  # Sum of actual scores obtained
    total_score = 0.0     # Sum of maximum possible scores

    # Iterate through the latest responses from each round
    latest_responses_by_round.each_value do |response|
      # Only consider responses that were submitted
      next unless response.is_submitted

      # Accumulate the obtained and maximum scores
      response_score += response.aggregate_questionnaire_score
      total_score += response.maximum_score
    end

    # Return the normalized score (as a float), or 0 if no valid total score
    total_score > 0 ? (response_score.to_f / total_score) : 0
  end
end