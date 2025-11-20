# frozen_string_literal: true

module DueDateActions
  extend ActiveSupport::Concern

  included do
    has_many :due_dates, as: :parent, dependent: :destroy
    include DueDateQueries
  end

  # Generic activity permission checker that determines if an activity is permissible
  # based on the current deadline state for this parent object
  def activity_permissible?(activity)
    current_deadline = next_due_date
    return false unless current_deadline

    current_deadline.activity_permissible?(activity)
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

  def metareview_permissible?
    activity_permissible?(:metareview)
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

  # Check activity permissions for a specific deadline type
  def activity_permissible_for_type?(activity, deadline_type_name)
    deadline = find_deadline(deadline_type_name)
    return false unless deadline

    deadline.activity_permissible?(activity)
  end

  # Get the current stage/deadline for a specific action
  def current_stage_for(action)
    current_deadline_for(action)
  end

  # Check if a specific action is currently allowed based on deadlines
  def action_allowed?(action)
    case action.to_s.downcase
    when 'submit', 'submission'
      submission_permissible?
    when 'review'
      review_permissible?
    when 'teammate_review'
      teammate_review_permissible?
    when 'metareview'
      metareview_permissible?
    when 'quiz'
      quiz_permissible?
    when 'team_formation'
      team_formation_permissible?
    when 'signup'
      signup_permissible?
    when 'drop_topic'
      drop_topic_permissible?
    else
      false
    end
  end

  # Get all currently allowed actions
  def allowed_actions
    actions = []
    actions << 'submission' if submission_permissible?
    actions << 'review' if review_permissible?
    actions << 'teammate_review' if teammate_review_permissible?
    actions << 'metareview' if metareview_permissible?
    actions << 'quiz' if quiz_permissible?
    actions << 'team_formation' if team_formation_permissible?
    actions << 'signup' if signup_permissible?
    actions << 'drop_topic' if drop_topic_permissible?
    actions
  end

  # Check if any actions are currently allowed
  def has_allowed_actions?
    allowed_actions.any?
  end

  # Get permission summary for all actions
  def action_permissions_summary
    {
      submission: submission_permissible?,
      review: review_permissible?,
      teammate_review: teammate_review_permissible?,
      metareview: metareview_permissible?,
      quiz: quiz_permissible?,
      team_formation: team_formation_permissible?,
      signup: signup_permissible?,
      drop_topic: drop_topic_permissible?,
      has_any_permissions: has_allowed_actions?
    }
  end

  # Topic-specific permission checking
  def activity_permissible_for_topic?(activity, topic_id)
    deadline = current_stage_for_topic(topic_id, activity)
    return false unless deadline

    deadline.activity_permissible?(activity)
  end

  # Topic-specific syntactic sugar methods
  def submission_permissible_for_topic?(topic_id)
    activity_permissible_for_topic?(:submission, topic_id)
  end

  def review_permissible_for_topic?(topic_id)
    activity_permissible_for_topic?(:review, topic_id)
  end

  def quiz_permissible_for_topic?(topic_id)
    activity_permissible_for_topic?(:quiz, topic_id)
  end

  # Copy all due dates to a new parent object
  def copy_due_dates_to(new_parent)
    due_dates.find_each do |due_date|
      due_date.copy_to(new_parent)
    end
  end

  # Duplicate due dates with modifications
  def duplicate_due_dates_with_changes(new_parent, changes = {})
    due_dates.map do |due_date|
      due_date.duplicate_with_changes(changes.merge(parent: new_parent))
    end
  end

  # Create a new due date for this parent
  def create_due_date(deadline_type_name, due_at, round: 1, **attributes)
    deadline_type = DeadlineType.find_by_name(deadline_type_name)
    raise ArgumentError, "Invalid deadline type: #{deadline_type_name}" unless deadline_type

    due_dates.create!(
      deadline_type: deadline_type,
      due_at: due_at,
      round: round,
      **attributes
    )
  end

  # Update or create a due date for a specific type and round
  def set_deadline(deadline_type_name, due_at, round: 1, **attributes)
    deadline = find_deadline(deadline_type_name, round)

    if deadline
      deadline.update!(due_at: due_at, **attributes)
      deadline
    else
      create_due_date(deadline_type_name, due_at, round: round, **attributes)
    end
  end

  # Remove due dates of a specific type
  def remove_deadlines_of_type(deadline_type_name)
    due_dates.joins(:deadline_type)
             .where(deadline_types: { name: deadline_type_name })
             .destroy_all
  end

  # Shift all deadlines by a certain amount of time
  def shift_deadlines(time_delta)
    due_dates.update_all("due_at = due_at + INTERVAL #{time_delta.to_i} SECOND")
  end

  # Shift deadlines of a specific type
  def shift_deadlines_of_type(deadline_type_name, time_delta)
    due_dates.joins(:deadline_type)
             .where(deadline_types: { name: deadline_type_name })
             .update_all("due_at = due_at + INTERVAL #{time_delta.to_i} SECOND")
  end

  # Check if deadlines are properly ordered (submission before review, etc.)
  def deadlines_properly_ordered?
    workflow_deadlines = due_dates.joins(:deadline_type)
                                  .where(deadline_types: { name: DeadlineType.workflow_order })
                                  .order(:due_at)

    previous_position = -1
    workflow_deadlines.each do |deadline|
      current_position = deadline.deadline_type.workflow_position
      return false if current_position < previous_position
      previous_position = current_position
    end

    true
  end

  # Get deadline ordering violations
  def deadline_ordering_violations
    violations = []
    workflow_deadlines = due_dates.joins(:deadline_type)
                                  .where(deadline_types: { name: DeadlineType.workflow_order })
                                  .order(:due_at)

    workflow_deadlines.each_with_index do |deadline, index|
      next_deadline = workflow_deadlines[index + 1]
      next unless next_deadline

      if deadline.deadline_type.workflow_position > next_deadline.deadline_type.workflow_position
        violations << {
          earlier_deadline: deadline,
          later_deadline: next_deadline,
          issue: "#{next_deadline.deadline_type_name} should come after #{deadline.deadline_type_name}"
        }
      end
    end

    violations
  end

  # Validate that all required deadline types are present
  def has_required_deadlines?(required_types = ['submission'])
    required_types.all? { |type| has_deadline_type?(type) }
  end

  # Get missing required deadline types
  def missing_required_deadlines(required_types = ['submission'])
    required_types.reject { |type| has_deadline_type?(type) }
  end

  # Check if this object has a complete deadline schedule
  def has_complete_deadline_schedule?
    has_deadline_type?('submission') &&
    (has_deadline_type?('review') || has_deadline_type?('quiz'))
  end

  # Get the workflow stage based on current time and deadlines
  def current_workflow_stage
    current_deadline = next_due_date
    return 'inactive' unless current_deadline

    if current_deadline.overdue?
      previous = current_deadline.previous_deadline
      return previous ? previous.deadline_type_name : 'pre-submission'
    else
      current_deadline.deadline_type_name
    end
  end

  # Check if object is in a specific workflow stage
  def in_stage?(stage_name)
    current_workflow_stage == stage_name
  end

  # Get all stages this object will go through
  def workflow_stages
    used_deadline_types.sort_by(&:workflow_position).map(&:name)
  end

  # Check if a stage has been completed
  def stage_completed?(stage_name)
    deadline = find_deadline(stage_name)
    return false unless deadline

    deadline.overdue?
  end

  # Get completion status for all stages
  def stage_completion_status
    workflow_stages.map do |stage|
      {
        stage: stage,
        completed: stage_completed?(stage),
        deadline: find_deadline(stage)
      }
    end
  end
end
