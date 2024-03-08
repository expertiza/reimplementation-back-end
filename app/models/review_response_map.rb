# frozen_string_literal: true

class ReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :contributor, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'reviewed_object_id', inverse_of: false

  # returns the assignment related to the response map
  def response_assignment
    return assignment
  end
  def get_questionnaire
    reviewees_topic = SignedUpTeam.topic_id_by_team_id(@contributor.id)
    @current_round = @assignment.number_of_current_round(reviewees_topic)
    @questionnaire = @map.questionnaire(@current_round, reviewees_topic)
  end
end
