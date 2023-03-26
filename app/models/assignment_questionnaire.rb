class AssignmentQuestionnaire < ApplicationRecord
  # The assignment_questionnaire defines a join between a questionnaire and an assignment
  belongs_to :questionnaire
  belongs_to :assignment
end