# frozen_string_literal: true

module DueDateActions
  # Generic activity permission checker that determines if an activity is permissible
  # based on the current deadline state for this parent object
  def activity_permissible?(activity)
    current_deadline = next_due_date()
    return false unless current_deadline

    current_deadline.activity_permissible?(activity)
  end

  # Activity permission checker for a specific deadline date (not current date)
  def activity_permissible_for?(activity, deadline_date)
    deadline = due_dates.where('due_at <= ?', deadline_date).order(:due_at).last
    return false unless deadline

    deadline.activity_permissible?(activity)
  end

  # Syntactic sugar methods for common activities
  # These provide clean, readable method names while avoiding DRY violations
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

  def team_formation_permissible?
    activity_permissible?(:team_formation)
  end

  def signup_permissible?
    activity_permissible?(:signup)
  end

  def drop_topic_permissible?
    activity_permissible?(:drop_topic)
  end

  # Get the next due date for this parent
  def next_due_date(topic_id = nil)
    if topic_id && has_topic_specific_deadlines?
      topic_deadline = due_dates.where(parent_id: topic_id, parent_type: 'ProjectTopic')
                               .where('due_at >= ?', Time.current)
                               .order(:due_at)
                               .first
      return topic_deadline if topic_deadline
    end

    due_dates.where('due_at >= ?', Time.current).order(:due_at).first
  end

  # Get the current stage name for display purposes
  def current_stage
    deadline = next_due_date()
    return 'finished' unless deadline

    deadline.deadline_type&.name || 'unknown'
  end

  # Check if assignment has topic-specific deadlines
  def has_topic_specific_deadlines?
    staggered_deadline || due_dates.where(parent_type: 'ProjectTopic').exists?
  end

  # Copy due dates to a new parent object
  def copy_due_dates_to(new_parent)
    due_dates.find_each do |due_date|
      new_due_date = due_date.dup
      new_due_date.parent = new_parent
      new_due_date.save!
    end
  end

  # Shift deadlines of a specific type by a time interval
  def shift_deadlines_of_type(deadline_type_name, days)
    due_dates.joins(:deadline_type)
             .where(deadline_types: { name: deadline_type_name })
             .update_all("due_at = due_at + INTERVAL #{days.to_i} DAY")
  end

  # Check if deadlines are in proper chronological order
  def deadlines_properly_ordered?
    sorted_deadlines = due_dates.order(:due_at)
    previous_date = nil

    sorted_deadlines.each do |deadline|
      return false if previous_date && deadline.due_at < previous_date
      previous_date = deadline.due_at
    end

    true
  end
end
