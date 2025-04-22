# frozen_string_literal: true

class ReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false

  # returns the assignment related to the response map
  def response_assignment
    return assignment
  end
  
  def self.get_responses_for_team_round(team, round)
    responses = []
    if team.id
      maps = ResponseMap.where(reviewee_id: team.id, type: 'ReviewResponseMap')
      maps.each do |map|
        if map.response.any? && map.response.reject { |r| (r.round != round || !r.is_submitted) }.any?
          responses << map.response.reject { |r| (r.round != round || !r.is_submitted) }.last
        end
      end
      responses.sort! { |a, b| a.map.reviewer.fullname <=> b.map.reviewer.fullname }
    end
    responses
  end
end
