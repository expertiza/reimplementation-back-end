# frozen_string_literal: true

module DueDatePermissions
  # Permission checking methods that combine deadline-based and role-based logic
  #
  # As Ed explained, these methods must check both:
  # 1. Whether the action is permitted by the current deadline (submission_allowed_id, review_allowed_id, etc.)
  # 2. Whether the participant has the necessary permissions (can_submit, can_review, can_take_quiz fields)
  #
  # The participant object represents how a user is participating in the assignment.
  # Not all participants can do all actions - some might only submit, others only review,
  # and others might only take quizzes. The can_* fields control these permissions.

  # Check if submission is allowed based on both deadline and participant permissions
  # @param participant [Participant, nil] The participant to check permissions for.
  #   If nil, only checks deadline-based permissions.
  # @return [Boolean] true if submission is allowed, false otherwise
  def can_submit?(participant = nil)
    return false unless submission_allowed_id
    return false if participant && !participant.can_submit

    deadline_right = DeadlineRight.find_by(id: submission_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  # Check if review is allowed based on both deadline and participant permissions
  # @param participant [Participant, nil] The participant to check permissions for.
  #   If nil, only checks deadline-based permissions.
  # @return [Boolean] true if review is allowed, false otherwise
  def can_review?(participant = nil)
    return false unless review_allowed_id
    return false if participant && !participant.can_review

    deadline_right = DeadlineRight.find_by(id: review_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  # Check if taking a quiz is allowed based on both deadline and participant permissions
  # @param participant [Participant, nil] The participant to check permissions for.
  #   If nil, only checks deadline-based permissions.
  # @return [Boolean] true if taking quiz is allowed, false otherwise
  def can_take_quiz?(participant = nil)
    return false unless quiz_allowed_id
    return false if participant && !participant.can_take_quiz

    deadline_right = DeadlineRight.find_by(id: quiz_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  # Check if teammate review is allowed based on both deadline and participant permissions
  # Note: teammate review uses the can_review permission field
  # @param participant [Participant, nil] The participant to check permissions for.
  #   If nil, only checks deadline-based permissions.
  # @return [Boolean] true if teammate review is allowed, false otherwise
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
