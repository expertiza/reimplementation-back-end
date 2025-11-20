# frozen_string_literal: true

class DueDate < ApplicationRecord
  include Comparable
  include DueDatePermissions

  belongs_to :parent, polymorphic: true
  belongs_to :deadline_type, foreign_key: :deadline_type_id

  validates :due_at, presence: true
  validates :deadline_type_id, presence: true
  validates :round, presence: true, numericality: { greater_than: 0 }
  validate :due_at_is_valid_datetime

  # Scopes for common queries
  scope :upcoming, -> { where('due_at > ?', Time.current).order(:due_at) }
  scope :overdue, -> { where('due_at < ?', Time.current).order(:due_at) }
  scope :for_round, ->(round_num) { where(round: round_num) }
  scope :for_deadline_type, ->(type_name) { joins(:deadline_type).where(deadline_types: { name: type_name }) }
  scope :active, -> { where('due_at > ?', Time.current) }

  # Instance methods for individual due date operations

  # Create a copy of this due date for a new parent
  def copy_to(new_parent)
    new_due_date = dup
    new_due_date.parent = new_parent
    new_due_date.save!
    new_due_date
  end

  # Duplicate this due date with different attributes
  def duplicate_with_changes(changes = {})
    new_due_date = dup
    changes.each { |attr, value| new_due_date.public_send("#{attr}=", value) }
    new_due_date.save!
    new_due_date
  end

  # Check if this deadline has passed
  def overdue?
    due_at < Time.current
  end

  # Check if this deadline is upcoming
  def upcoming?
    due_at > Time.current
  end

  # Check if this deadline is today
  def due_today?
    due_at.to_date == Time.current.to_date
  end

  # Check if this deadline is this week
  def due_this_week?
    due_at >= Time.current.beginning_of_week && due_at <= Time.current.end_of_week
  end

  # Time remaining until deadline (returns nil if overdue)
  def time_remaining
    return nil if overdue?

    due_at - Time.current
  end

  # Time since deadline passed (returns nil if not overdue)
  def time_overdue
    return nil unless overdue?

    Time.current - due_at
  end

  # Get human-readable time description
  def time_description
    if due_today?
      "Due today at #{due_at.strftime('%I:%M %p')}"
    elsif overdue?
      days_overdue = (Time.current.to_date - due_at.to_date).to_i
      "#{days_overdue} day#{'s' if days_overdue != 1} overdue"
    elsif upcoming?
      days_until = (due_at.to_date - Time.current.to_date).to_i
      if days_until == 0
        "Due today"
      elsif days_until == 1
        "Due tomorrow"
      else
        "Due in #{days_until} days"
      end
    else
      "Due #{due_at.strftime('%B %d, %Y')}"
    end
  end

  # Check if this deadline is for a specific type of activity
  def for_submission?
    deadline_type&.submission?
  end

  def for_review?
    deadline_type&.review?
  end

  def for_quiz?
    deadline_type&.quiz?
  end

  def for_teammate_review?
    deadline_type&.teammate_review?
  end

  def for_metareview?
    deadline_type&.metareview?
  end

  def for_team_formation?
    deadline_type&.team_formation?
  end

  def for_signup?
    deadline_type&.signup?
  end

  def for_topic_drop?
    deadline_type&.drop_topic?
  end

  # Get the deadline type name
  def deadline_type_name
    deadline_type&.name
  end

  # Get human-readable deadline type
  def deadline_type_display
    deadline_type&.display_name || 'Unknown'
  end

  # Check if this deadline allows late submissions
  def allows_late_work?
    allows_late_submission? || allows_late_review? || allows_late_quiz?
  end

  # Get status description
  def status_description
    if overdue?
      allows_late_work? ? 'Overdue (Late work accepted)' : 'Closed'
    elsif due_today?
      'Due today'
    elsif upcoming?
      time_description
    else
      'Unknown status'
    end
  end

  # Check if this deadline is currently in effect
  def currently_active?
    active? && (upcoming? || (overdue? && allows_late_work?))
  end

  # Get the next deadline after this one (for the same parent)
  def next_deadline
    parent.due_dates
          .where('due_at > ? OR (due_at = ? AND id > ?)', due_at, due_at, id)
          .order(:due_at, :id)
          .first
  end

  # Get the previous deadline before this one (for the same parent)
  def previous_deadline
    parent.due_dates
          .where('due_at < ? OR (due_at = ? AND id < ?)', due_at, due_at, id)
          .order(due_at: :desc, id: :desc)
          .first
  end

  # Check if this is the last deadline for the parent
  def last_deadline?
    next_deadline.nil?
  end

  # Check if this is the first deadline for the parent
  def first_deadline?
    previous_deadline.nil?
  end

  # Comparison method for sorting
  def <=>(other)
    return nil unless other.is_a?(DueDate)

    # Primary sort: due_at
    comparison = due_at <=> other.due_at
    return comparison unless comparison.zero?

    # Secondary sort: deadline type workflow order
    if deadline_type && other.deadline_type
      workflow_comparison = deadline_type.workflow_position <=> other.deadline_type.workflow_position
      return workflow_comparison unless workflow_comparison.zero?
    end

    # Tertiary sort: id for consistency
    id <=> other.id
  end

  # Get all due dates for the same round and parent
  def round_siblings
    parent.due_dates.where(round: round).where.not(id: id).order(:due_at)
  end

  # Check if this deadline conflicts with others in the same round
  def has_round_conflicts?
    round_siblings.where(deadline_type_id: deadline_type_id).exists?
  end

  # Get summary information about this deadline
  def summary
    {
      id: id,
      deadline_type: deadline_type_name,
      due_at: due_at,
      round: round,
      overdue: overdue?,
      upcoming: upcoming?,
      currently_active: currently_active?,
      time_description: time_description,
      status: status_description,
      permissions: permissions_summary
    }
  end

  # String representation
  def to_s
    "#{deadline_type_display} - #{time_description}"
  end

  # Detailed string representation
  def inspect_details
    "DueDate(id: #{id}, type: #{deadline_type_name}, due: #{due_at}, " \
    "round: #{round}, parent: #{parent_type}##{parent_id})"
  end

  # Class methods for collection operations
  class << self
    # Sort a collection of due dates
    def sort_by_due_date(due_dates)
      due_dates.sort
    end

    # Find the next upcoming due date from a collection
    def next_from_collection(due_dates)
      due_dates.select(&:upcoming?).min
    end

    # Check if any due dates in collection allow late work
    def any_allow_late_work?(due_dates)
      due_dates.any?(&:allows_late_work?)
    end

    # Get due dates grouped by deadline type
    def group_by_type(due_dates)
      due_dates.group_by(&:deadline_type_name)
    end

    # Get due dates grouped by round
    def group_by_round(due_dates)
      due_dates.group_by(&:round)
    end

    # Filter due dates that are currently actionable
    def currently_actionable(due_dates)
      due_dates.select(&:currently_active?)
    end

    # Get statistics for a collection of due dates
    def collection_stats(due_dates)
      {
        total: due_dates.count,
        upcoming: due_dates.count(&:upcoming?),
        overdue: due_dates.count(&:overdue?),
        due_today: due_dates.count(&:due_today?),
        active: due_dates.count(&:currently_active?),
        types: due_dates.map(&:deadline_type_name).uniq.compact.sort
      }
    end

    # Find deadline conflicts in a collection
    def find_conflicts(due_dates)
      conflicts = []

      due_dates.group_by(&:round).each do |round, round_deadlines|
        round_deadlines.group_by(&:deadline_type_name).each do |type, type_deadlines|
          if type_deadlines.count > 1
            conflicts << {
              round: round,
              deadline_type: type,
              conflicting_deadlines: type_deadlines.map(&:id)
            }
          end
        end
      end

      conflicts
    end

    # Get upcoming deadlines across all due dates
    def upcoming_across_all(limit: 10)
      upcoming.limit(limit).includes(:deadline_type, :parent)
    end

    # Get overdue deadlines across all due dates
    def overdue_across_all(limit: 10)
      overdue.limit(limit).includes(:deadline_type, :parent)
    end
  end

  private

  def due_at_is_valid_datetime
    return unless due_at.present?

    unless due_at.is_a?(Time) || due_at.is_a?(DateTime) || due_at.is_a?(Date)
      errors.add(:due_at, 'must be a valid datetime')
    end

    if due_at.is_a?(Date)
      errors.add(:due_at, 'should include time information, not just date')
    end
  end
end
