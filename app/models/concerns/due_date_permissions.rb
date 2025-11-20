# frozen_string_literal: true

module DueDatePermissions
  extend ActiveSupport::Concern

  # Permission checking methods that combine deadline-based and role-based logic
  # These methods provide a unified interface for checking if actions are allowed

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

  def can_teammate_review?
    return false unless teammate_review_allowed_id

    deadline_right = DeadlineRight.find_by(id: teammate_review_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  def can_metareview?
    return false unless respond_to?(:metareview_allowed_id) && metareview_allowed_id

    deadline_right = DeadlineRight.find_by(id: metareview_allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  # Generic permission checker that can be extended for any action
  def activity_permissible?(activity)
    permission_field = "#{activity}_allowed_id"
    return false unless respond_to?(permission_field)

    allowed_id = public_send(permission_field)
    return false unless allowed_id

    deadline_right = DeadlineRight.find_by(id: allowed_id)
    deadline_right&.name&.in?(%w[OK Late])
  end

  # Syntactic sugar methods for common activities
  def submission_permissible?
    activity_permissible?(:submission)
  end

  def review_permissible?
    activity_permissible?(:review)
  end

  def teammate_review_permissible?
    activity_permissible?(:teammate_review)
  end

  def quiz_permissible?
    activity_permissible?(:quiz)
  end

  def metareview_permissible?
    activity_permissible?(:metareview) if respond_to?(:metareview_allowed_id)
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

  # Check if any activity is currently allowed
  def has_any_permission?
    can_submit? || can_review? || can_take_quiz? || can_teammate_review? ||
      (respond_to?(:can_metareview?) && can_metareview?)
  end

  # Get list of currently allowed activities
  def allowed_activities
    activities = []
    activities << 'submission' if can_submit?
    activities << 'review' if can_review?
    activities << 'quiz' if can_take_quiz?
    activities << 'teammate_review' if can_teammate_review?
    activities << 'metareview' if respond_to?(:can_metareview?) && can_metareview?
    activities
  end

  # Check if this deadline is currently active (allows some action)
  def active?
    has_any_permission?
  end

  # Check if this deadline is completely closed (no actions allowed)
  def closed?
    !active?
  end

  # Check permissions for deadline type compatibility
  def deadline_type_permits_action?(action)
    return false unless deadline_type

    case action.to_s.downcase
    when 'submit', 'submission'
      deadline_type.allows_submission?
    when 'review'
      deadline_type.allows_review?
    when 'quiz'
      deadline_type.allows_quiz?
    when 'teammate_review'
      deadline_type.allows_review?
    when 'metareview'
      deadline_type.allows_review?
    else
      false
    end
  end

  # Comprehensive permission check combining deadline type and deadline rights
  def permits_action?(action)
    deadline_type_permits_action?(action) && activity_permissible?(action)
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

  # Check if deadline is in grace period (allows late submissions)
  def in_grace_period_for?(action)
    permission_status_for(action) == 'Late'
  end

  # Check if deadline is fully open for action
  def fully_open_for?(action)
    permission_status_for(action) == 'OK'
  end

  # Get human-readable permission description
  def permission_description_for(action)
    status = permission_status_for(action)
    case status
    when 'OK'
      "#{action.to_s.humanize} is allowed"
    when 'Late'
      "#{action.to_s.humanize} is allowed with late penalty"
    when 'No'
      "#{action.to_s.humanize} is not allowed"
    else
      "#{action.to_s.humanize} status unknown"
    end
  end

  # Get a summary of all permissions for this deadline
  def permissions_summary
    {
      submission: permission_status_for(:submission),
      review: permission_status_for(:review),
      quiz: permission_status_for(:quiz),
      teammate_review: permission_status_for(:teammate_review),
      active: active?,
      closed: closed?
    }
  end
end
