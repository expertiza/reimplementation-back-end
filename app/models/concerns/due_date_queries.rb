# frozen_string_literal: true

module DueDateQueries
  # Get next due date for this parent
  def next_due_date(topic_id = nil)
    if topic_id && has_topic_specific_deadlines?
      topic_deadline = due_dates.where(parent_id: topic_id, parent_type: 'SignUpTopic')
                               .where('due_at >= ?', Time.current)
                               .order(:due_at)
                               .first
      return topic_deadline if topic_deadline
    end

    due_dates.where('due_at >= ?', Time.current).order(:due_at).first
  end

  # Get all deadlines for a topic (topic-specific + assignment fallback)
  def deadlines_for_topic(topic_id)
    assignment_deadlines = due_dates.where(parent_type: 'Assignment')
    topic_deadlines = due_dates.where(parent_id: topic_id, parent_type: 'SignUpTopic')

    (assignment_deadlines + topic_deadlines).sort_by(&:due_at)
  end

  # Check if assignment has topic-specific deadlines
  def has_topic_specific_deadlines?
    due_dates.where(parent_type: 'SignUpTopic').exists?
  end

  private

  # Map action names to deadline type names for lookup
  def action_to_deadline_type(action)
    {
      'submit' => 'submission',
      'submission' => 'submission',
      'review' => 'review',
      'teammate_review' => 'teammate_review',
      'quiz' => 'quiz',
      'team_formation' => 'team_formation',
      'signup' => 'signup',
      'drop_topic' => 'drop_topic'
    }[action.to_s.downcase]
  end
end
