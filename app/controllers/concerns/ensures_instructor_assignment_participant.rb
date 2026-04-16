# frozen_string_literal: true

# Ensures the logged-in teaching user has an AssignmentParticipant row for the assignment
# (required for calibration APIs that key ResponseMap.reviewer_id off participant id).
module EnsuresInstructorAssignmentParticipant
  extend ActiveSupport::Concern

  private

  def ensure_instructor_assignment_participant!(assignment)
    @instructor_participant_save_errors = nil
    p = AssignmentParticipant.find_or_initialize_by(parent_id: assignment.id, user_id: current_user.id)
    return p if p.persisted?

    p.handle = current_user.handle.presence || current_user.name
    p.can_submit = false
    p.can_review = true
    return p if p.save

    @instructor_participant_save_errors = p.errors.full_messages
    nil
  end
end
