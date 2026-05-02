# frozen_string_literal: true

class ReviewResetArchive < ApplicationRecord
  validates :response_id, :map_id, :assignment_id, :questionnaire_id, :reset_reason, :snapshot_data, presence: true
end
