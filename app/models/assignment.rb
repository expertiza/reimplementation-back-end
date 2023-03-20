class Assignment < ApplicationRecord
  def review_questionnaire_id
    Questionnaire.find_by_assignment_id id
  end
end
