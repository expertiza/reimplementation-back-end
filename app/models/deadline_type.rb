# frozen_string_literal: true

# DeadlineType serves as the canonical source of truth for all deadline categories.
# It replaces hard-coded deadline_type_id comparisons with semantic helper methods.
class DeadlineType < ApplicationRecord
  # Constants for deadline type IDs (for backward compatibility)
  SUBMISSION = 1
  REVIEW = 2
  TEAMMATE_REVIEW = 3
  METAREVIEW = 5
  DROP_TOPIC = 6
  SIGNUP = 7
  TEAM_FORMATION = 8
  QUIZ = 11

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  has_many :due_dates, foreign_key: :deadline_type_id, dependent: :restrict_with_exception

  # Scopes for categorizing deadline types
  scope :submission_types, -> { where(name: ['submission']) }
  scope :review_types, -> { where(name: ['review', 'metareview', 'teammate_review']) }
  scope :quiz_types, -> { where(name: ['quiz']) }
  scope :administrative_types, -> { where(name: ['drop_topic', 'signup', 'team_formation']) }

  # Class methods for finding deadline types
  def self.find_by_name(name)
    find_by(name: name.to_s)
  end

  def self.submission
    find_by_name('submission')
  end

  def self.review
    find_by_name('review')
  end

  def self.teammate_review
    find_by_name('teammate_review')
  end

  def self.metareview
    find_by_name('metareview')
  end

  def self.drop_topic
    find_by_name('drop_topic')
  end

  def self.signup
    find_by_name('signup')
  end

  def self.team_formation
    find_by_name('team_formation')
  end

  def self.quiz
    find_by_name('quiz')
  end

  # Dynamic method to find deadline type for action
  def self.for_action(action_name)
    case action_name.to_s.downcase
    when 'submit', 'submission' then submission
    when 'review' then review
    when 'teammate_review' then teammate_review
    when 'metareview' then metareview
    when 'quiz' then quiz
    when 'team_formation' then team_formation
    when 'signup' then signup
    when 'drop_topic' then drop_topic
    else nil
    end
  end

  # Semantic helper methods for deadline type identification
  def submission?
    name == 'submission'
  end

  def review?
    %w[review metareview teammate_review].include?(name)
  end

  def teammate_review?
    name == 'teammate_review'
  end

  def metareview?
    name == 'metareview'
  end

  def quiz?
    name == 'quiz'
  end

  def administrative?
    %w[drop_topic signup team_formation].include?(name)
  end

  def team_formation?
    name == 'team_formation'
  end

  def signup?
    name == 'signup'
  end

  def drop_topic?
    name == 'drop_topic'
  end

  # Permission checking helper methods
  def allows_submission?
    submission?
  end

  def allows_review?
    review?
  end

  def allows_quiz?
    quiz?
  end

  def allows_team_formation?
    team_formation?
  end

  def allows_signup?
    signup?
  end

  def allows_topic_drop?
    drop_topic?
  end

  # Category checking methods
  def workflow_deadline?
    %w[submission review teammate_review metareview].include?(name)
  end

  def assessment_deadline?
    %w[review metareview teammate_review quiz].include?(name)
  end

  def student_action_deadline?
    %w[submission quiz signup team_formation drop_topic].include?(name)
  end

  # Display methods
  def display_name
    name.humanize
  end

  def to_s
    display_name
  end

  # Method to seed the deadline types (for use in migrations/seeds)
  def self.seed_deadline_types!
    deadline_types = [
      { id: SUBMISSION, name: 'submission', description: 'Student work submission deadlines' },
      { id: REVIEW, name: 'review', description: 'Peer review deadlines' },
      { id: TEAMMATE_REVIEW, name: 'teammate_review', description: 'Team member evaluation deadlines' },
      { id: METAREVIEW, name: 'metareview', description: 'Meta-review deadlines' },
      { id: DROP_TOPIC, name: 'drop_topic', description: 'Topic drop deadlines' },
      { id: SIGNUP, name: 'signup', description: 'Course/assignment signup deadlines' },
      { id: TEAM_FORMATION, name: 'team_formation', description: 'Team formation deadlines' },
      { id: QUIZ, name: 'quiz', description: 'Quiz completion deadlines' }
    ]

    deadline_types.each do |type_attrs|
      find_or_create_by(id: type_attrs[:id]) do |dt|
        dt.name = type_attrs[:name]
        dt.description = type_attrs[:description]
      end
    end
  end

  # Method to clean up duplicate entries
  def self.cleanup_duplicates!
    # Remove any duplicate team_formation entries (keep canonical ID 8)
    where(name: 'team_formation').where.not(id: TEAM_FORMATION).destroy_all

    # Update any due_dates that reference deleted duplicates
    ActiveRecord::Base.connection.execute(<<~SQL)
      UPDATE due_dates
      SET deadline_type_id = #{TEAM_FORMATION}
      WHERE deadline_type_id NOT IN (#{all.pluck(:id).join(',')})
      AND deadline_type_id IS NOT NULL
    SQL
  end

  # Validation methods
  def self.valid_deadline_names
    %w[submission review teammate_review metareview drop_topic signup team_formation quiz]
  end

  def self.validate_deadline_name(name)
    valid_deadline_names.include?(name.to_s)
  end

  # Query helpers for associations
  def self.used_in_assignments
    joins(:due_dates)
      .where(due_dates: { parent_type: 'Assignment' })
      .distinct
  end

  def self.used_in_topics
    joins(:due_dates)
      .where(due_dates: { parent_type: 'SignUpTopic' })
      .distinct
  end

  # Statistics methods
  def due_dates_count
    due_dates.count
  end

  def active_due_dates_count
    due_dates.where('due_at > ?', Time.current).count
  end

  def overdue_count
    due_dates.where('due_at < ?', Time.current).count
  end

  # Comparison and ordering
  def <=>(other)
    return nil unless other.is_a?(DeadlineType)

    id <=> other.id
  end

  # Class method to get deadline type hierarchy for workflow
  def self.workflow_order
    %w[signup team_formation submission review teammate_review metareview quiz drop_topic]
  end

  def workflow_position
    self.class.workflow_order.index(name) || Float::INFINITY
  end

  # Method to check if this deadline type typically comes before another
  def comes_before?(other_type)
    return false unless other_type.is_a?(DeadlineType)

    workflow_position < other_type.workflow_position
  end

  # Method to get the next logical deadline type in workflow
  def next_in_workflow
    current_pos = workflow_position
    return nil if current_pos == Float::INFINITY

    next_name = self.class.workflow_order[current_pos + 1]
    return nil unless next_name

    self.class.find_by_name(next_name)
  end

  # Method to get the previous logical deadline type in workflow
  def previous_in_workflow
    current_pos = workflow_position
    return nil if current_pos <= 0

    prev_name = self.class.workflow_order[current_pos - 1]
    return nil unless prev_name

    self.class.find_by_name(prev_name)
  end

  # Method for dynamic permission checking based on action
  def allows_action?(action)
    case action.to_s.downcase
    when 'submit', 'submission' then allows_submission?
    when 'review' then allows_review?
    when 'quiz' then allows_quiz?
    when 'team_formation' then allows_team_formation?
    when 'signup' then allows_signup?
    when 'drop_topic' then allows_topic_drop?
    else false
    end
  end

  private

  # Ensure we maintain referential integrity
  def cannot_delete_if_has_due_dates
    return unless due_dates.exists?

    errors.add(:base, 'Cannot delete deadline type that has associated due dates')
    throw :abort
  end

  before_destroy :cannot_delete_if_has_due_dates
end
