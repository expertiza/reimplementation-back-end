class ResponseMap < ApplicationRecord
  has_many :response, foreign_key: 'map_id', dependent: :destroy, inverse_of: false
  belongs_to :reviewer, class_name: 'Participant', foreign_key: 'reviewer_id', inverse_of: false
  belongs_to :reviewee, class_name: 'Participant', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false
  belongs_to :questionnaire, class_name: 'Questionnaire', foreign_key: 'reviewed_object_id', optional: true

  alias map_id id

  # Returns the assignment related to the response map.
  def response_assignment
    Participant.find(self.reviewer_id).assignment
  end

  # Retrieves all the responses for a given team.
  # This method sorts the responses and returns the latest response for each map.
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
      # Sort responses by the reviewer's full name.
      responses = responses.sort { |a, b| a.map.reviewer.fullname <=> b.map.reviewer.fullname }
    end
    responses
  end

  # Deletes the associated response and then destroys the response map itself.
  def delete
    response.delete unless response.nil?
    destroy
  end

  # Retrieves all mappings for a given reviewer (participant).
  def self.mappings_for_reviewer(participant_id)
    where(reviewer_id: participant_id)
  end
end
