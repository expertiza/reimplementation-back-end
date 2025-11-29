# frozen_string_literal: true

module DueDatePermissions
  # Permission checking methods that combine deadline-based and role-based logic
  # These methods also need to check the can_submit, can_review, etc. fields of the Participant object

  def can_submit?(participant = nil)
    return false unless submission_allowed_id
    return false if participant && !participant.can_submit

    deadline_right = DeadlineRight.find_by(id: submission_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  def can_review?(participant = nil)
    return false unless review_allowed_id
    return false if participant && !participant.can_review

    deadline_right = DeadlineRight.find_by(id: review_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  def can_take_quiz?(participant = nil)
    return false unless quiz_allowed_id
    return false if participant && !participant.can_take_quiz

    deadline_right = DeadlineRight.find_by(id: quiz_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  def can_review_teammate?(participant = nil)
    return false unless teammate_review_allowed_id
    return false if participant && !participant.can_review

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
  def late_submission_allowed?
    return false unless submission_allowed_id

    deadline_right = DeadlineRight.find_by(id: submission_allowed_id)
    deadline_right&.name == 'Late'
  end

  def late_review_allowed?
    return false unless review_allowed_id

    deadline_right = DeadlineRight.find_by(id: review_allowed_id)
    deadline_right&.name == 'Late'
  end

  def late_quiz_allowed?
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
end
