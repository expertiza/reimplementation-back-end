class Assignment < ApplicationRecord
  include MetricHelper
  has_many :invitations
  has_many :questionnaires

  def review_questionnaire_id
    Questionnaire.find_by_assignment_id id
  end

  def num_review_rounds
    rounds_of_reviews
  end
end
