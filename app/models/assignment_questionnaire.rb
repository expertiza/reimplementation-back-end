class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :questionnaire
  belongs_to :assignment
end