# frozen_string_literal: true

# Stores an instructor-assigned grade and comment for a reviewer's overall
# contribution on an assignment. One record per reviewer (participant), not per
# individual review map, matching the old Expertiza review_grades schema.
class ReviewGrade < ApplicationRecord
  belongs_to :participant

  validates :grade_for_reviewer, numericality: { allow_nil: true }

  # Returns the weight to apply when computing a weighted peer score.
  # Defaults to 1.0 when the reviewer has no grade, giving them equal weight.
  # Override this method to change how reviewer grades translate to weights
  # (e.g. a non-linear curve) without touching the scoring logic in the controller.
  def self.reviewer_weight(grade_for_reviewer)
    grade_for_reviewer || 1.0
  end
end
