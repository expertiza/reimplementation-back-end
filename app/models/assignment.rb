class Assignment < ApplicationRecord
    has_many :questionnaires

    def review_questionnaire_id
      Questionnaire.find_by_assignment_id id
    end

    def num_review_rounds
      2
    end
end
  