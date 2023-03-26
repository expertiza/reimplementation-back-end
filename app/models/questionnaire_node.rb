class QuestionnaireNode < ApplicationRecord
  # Node object belonging to a questionnaire
  belongs_to :questionnaire
end