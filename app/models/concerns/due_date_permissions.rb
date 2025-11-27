# frozen_string_literal: true

module DueDatePermissions
  # Permission checking methods that combine deadline-based and role-based logic

  def can_submit?
    return false unless submission_allowed_id

    deadline_right = DeadlineRight.find_by(id: submission_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  def can_review?
    return false unless review_allowed_id

    deadline_right = DeadlineRight.find_by(id: review_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  def can_take_quiz?
    return false unless quiz_allowed_id

    deadline_right = DeadlineRight.find_by(id: quiz_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  def can_review_teammate?
    return false unless teammate_review_allowed_id

    deadline_right = DeadlineRight.find_by(id: teammate_review_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  # Generic permission checker
  def activity_permissible?(activity)
    permission_field = "#{activity}_allowed_id"
    return false unless respond_to?(permission_field)

    allowed_id = public_send(permission_field)
    return false unless allowed_id

    deadline_right = DeadlineRight.find_by(id: allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  # Check if deadline allows late submissions
  def allows_late_submission?
    return false unless submission_allowed_id

    deadline_right = DeadlineRight.find_by(id: submission_allowed_id)
    deadline_right&.name == 'Late'
  end

  def allows_late_review?
    return false unless review_allowed_id

    deadline_right = DeadlineRight.find_by(id: review_allowed_id)
    deadline_right&.name == 'Late'
  end

  def allows_late_quiz?
    return false unless quiz_allowed_id

    deadline_right = DeadlineRight.find_by(id: quiz_allowed_id)
    deadline_right&.name == 'Late'
  end

  # Get permission status for an action (OK, Late, No)
  def permission_status_for(action)
    permission_field = "#{action}_allowed_id"
    return 'No' unless respond_to?(permission_field)

    allowed_id = public_send(permission_field)
    return 'No' unless allowed_id

    deadline_right = DeadlineRight.find_by(id: allowed_id)
    deadline_right&.name || 'No'
  end

  # Get a summary of all permissions for this deadline
  def permissions_summary
    {
      submission: permission_status_for(:submission),
      review: permission_status_for(:review),
      quiz: permission_status_for(:quiz),
      teammate_review: permission_status_for(:teammate_review)
    }
  end
end
