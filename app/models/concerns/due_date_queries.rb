# frozen_string_literal: true

module DueDateQueries
  extend ActiveSupport::Concern

  included do
    # Scopes for common deadline queries
    scope :upcoming, -> { where('due_at > ?', Time.current).order(:due_at) }
    scope :overdue, -> { where('due_at < ?', Time.current).order(:due_at) }
    scope :today, -> { where(due_at: Time.current.beginning_of_day..Time.current.end_of_day) }
    scope :this_week, -> { where(due_at: Time.current.beginning_of_week..Time.current.end_of_week) }
    scope :for_deadline_type, ->(type_name) { joins(:deadline_type).where(deadline_types: { name: type_name }) }
    scope :for_round, ->(round_num) { where(round: round_num) }
    scope :active_deadlines, -> { where('due_at > ?', Time.current) }
    scope :by_deadline_type, -> { joins(:deadline_type).order('deadline_types.name') }
  end

  class_methods do
    # Find next upcoming deadline for any parent
    def next_deadline
      upcoming.first
    end

    # Find deadlines by type name
    def of_type(deadline_type_name)
      joins(:deadline_type).where(deadline_types: { name: deadline_type_name })
    end

    # Get deadline statistics
    def deadline_stats
      {
        total: count,
        upcoming: upcoming.count,
        overdue: overdue.count,
        today: today.count,
        this_week: this_week.count
      }
    end

    # Find deadlines within a date range
    def between_dates(start_date, end_date)
      where(due_at: start_date..end_date)
    end

    # Find deadlines for specific actions
    def for_submission
      of_type('submission')
    end

    def for_review
      of_type('review')
    end

    def for_quiz
      of_type('quiz')
    end

    def for_teammate_review
      of_type('teammate_review')
    end

    def for_metareview
      of_type('metareview')
    end

    # Find deadlines that allow specific actions
    def allowing_submission
      where(submission_allowed_id: [2, 3]) # Late and OK
    end

    def allowing_review
      where(review_allowed_id: [2, 3]) # Late and OK
    end

    def allowing_quiz
      where(quiz_allowed_id: [2, 3]) # Late and OK
    end

    # Get deadlines grouped by type
    def grouped_by_type
      joins(:deadline_type)
        .group('deadline_types.name')
        .order('deadline_types.name')
    end
  end

  # Instance methods for parent objects (Assignment, SignUpTopic)
  # These methods should be included in Assignment and SignUpTopic models

  # Get next due date for this parent
  def next_due_date
    due_dates.upcoming.first
  end

  # Get the most recently passed deadline
  def last_due_date
    due_dates.overdue.order(due_at: :desc).first
  end

  # Find current stage/deadline for a specific action
  def current_deadline_for(action)
    deadline_type_name = map_action_to_deadline_type(action)
    return nil unless deadline_type_name

    # First try to find an active deadline for this action
    current = due_dates
              .joins(:deadline_type)
              .where(deadline_types: { name: deadline_type_name })
              .where('due_at >= ?', Time.current)
              .order(:due_at)
              .first

    # If no future deadline, get the most recent past deadline
    current ||= due_dates
                .joins(:deadline_type)
                .where(deadline_types: { name: deadline_type_name })
                .order(due_at: :desc)
                .first

    current
  end

  # Get upcoming deadlines with limit
  def upcoming_deadlines(limit: 5)
    due_dates.upcoming.limit(limit)
  end

  # Get overdue deadlines
  def overdue_deadlines
    due_dates.overdue
  end

  # Check if there are any future deadlines
  def has_future_deadlines?
    due_dates.upcoming.exists?
  end

  # Get deadlines for a specific round
  def deadlines_for_round(round_number)
    due_dates.where(round: round_number).order(:due_at)
  end

  # Find deadline by type and round
  def find_deadline(deadline_type_name, round_number = nil)
    query = due_dates.joins(:deadline_type).where(deadline_types: { name: deadline_type_name })
    query = query.where(round: round_number) if round_number
    query.order(:due_at).first
  end

  # Get all deadline types used by this object
  def used_deadline_types
    due_dates
      .joins(:deadline_type)
      .select('DISTINCT deadline_types.*')
      .map(&:deadline_type)
  end

  # Check if this object has a specific type of deadline
  def has_deadline_type?(deadline_type_name)
    due_dates
      .joins(:deadline_type)
      .where(deadline_types: { name: deadline_type_name })
      .exists?
  end

  # Get deadlines that are currently active (allowing some action)
  def active_deadlines
    due_dates.select(&:active?)
  end

  # Get deadline summary for display
  def deadline_summary
    {
      total_deadlines: due_dates.count,
      upcoming_count: upcoming_deadlines.count,
      overdue_count: overdue_deadlines.count,
      deadline_types: used_deadline_types.map(&:name),
      next_deadline: next_due_date,
      has_active_deadlines: active_deadlines.any?
    }
  end

  # Find the current stage for topic-specific deadlines
  def current_stage_for_topic(topic_id, action)
    deadline_type_name = map_action_to_deadline_type(action)
    return nil unless deadline_type_name

    # Try topic-specific deadline first
    topic_deadline = due_dates
                     .joins(:deadline_type)
                     .where(parent_id: topic_id, parent_type: 'SignUpTopic')
                     .where(deadline_types: { name: deadline_type_name })
                     .where('due_at >= ?', Time.current)
                     .order(:due_at)
                     .first

    # Fall back to assignment-level deadline
    topic_deadline || current_deadline_for(action)
  end

  # Get all deadlines affecting a specific topic
  def deadlines_for_topic(topic_id)
    assignment_deadlines = due_dates.where(parent_type: 'Assignment')
    topic_deadlines = due_dates.where(parent_id: topic_id, parent_type: 'SignUpTopic')

    (assignment_deadlines + topic_deadlines).sort_by(&:due_at)
  end

  # Check if assignment has topic-specific overrides
  def has_topic_deadline_overrides?
    due_dates.where(parent_type: 'SignUpTopic').exists?
  end

  # Get deadline comparison between assignment and topic
  def deadline_comparison_for_topic(topic_id)
    assignment_deadlines = due_dates.where(parent_type: 'Assignment').includes(:deadline_type)
    topic_deadlines = due_dates.where(parent_id: topic_id, parent_type: 'SignUpTopic').includes(:deadline_type)

    {
      assignment_deadlines: assignment_deadlines,
      topic_deadlines: topic_deadlines,
      has_overrides: topic_deadlines.any?
    }
  end

  # Find conflicts between assignment and topic deadlines
  def deadline_conflicts_for_topic(topic_id)
    conflicts = []

    used_deadline_types.each do |deadline_type|
      assignment_deadline = find_deadline(deadline_type.name)
      topic_deadline = due_dates
                       .joins(:deadline_type)
                       .where(parent_id: topic_id, parent_type: 'SignUpTopic')
                       .where(deadline_types: { name: deadline_type.name })
                       .first

      if assignment_deadline && topic_deadline
        if assignment_deadline.due_at != topic_deadline.due_at
          conflicts << {
            deadline_type: deadline_type.name,
            assignment_due: assignment_deadline.due_at,
            topic_due: topic_deadline.due_at,
            difference: topic_deadline.due_at - assignment_deadline.due_at
          }
        end
      end
    end

    conflicts
  end

  # Get the effective deadline for a topic (topic-specific or assignment fallback)
  def effective_deadline_for_topic(topic_id, deadline_type_name)
    # First check for topic-specific deadline
    topic_deadline = due_dates
                     .joins(:deadline_type)
                     .where(parent_id: topic_id, parent_type: 'SignUpTopic')
                     .where(deadline_types: { name: deadline_type_name })
                     .first

    # Fall back to assignment deadline
    topic_deadline || find_deadline(deadline_type_name)
  end

  private

  # Map action names to deadline type names
  def map_action_to_deadline_type(action)
    case action.to_s.downcase
    when 'submit', 'submission'
      'submission'
    when 'review', 'peer_review'
      'review'
    when 'teammate_review'
      'teammate_review'
    when 'metareview', 'meta_review'
      'metareview'
    when 'quiz'
      'quiz'
    when 'team_formation'
      'team_formation'
    when 'signup'
      'signup'
    when 'drop_topic'
      'drop_topic'
    else
      nil
    end
  end
end
