# frozen_string_literal: true

class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment, inverse_of: :assignment_questionnaires
  belongs_to :questionnaire
end
