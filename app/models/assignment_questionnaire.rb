class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire
  belongs_to :sign_up_topic
end
