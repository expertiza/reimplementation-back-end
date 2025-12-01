# frozen_string_literal: true

class DueDate < ApplicationRecord
  include DueDatePermissions

  belongs_to :parent, polymorphic: true
  belongs_to :deadline_type, foreign_key: :deadline_type_id

  validates :due_at, presence: true
  validates :deadline_type_id, presence: true
  validates :parent, presence: true
  validates :round, numericality: { greater_than: 0 }, allow_nil: true
  validate :due_at_is_valid_datetime

  # Scopes for common queries
  scope :upcoming, -> { where('due_at > ?', Time.current).order(:due_at) }
  scope :overdue, -> { where('due_at < ?', Time.current).order(:due_at) }
  scope :for_round, ->(round_num) { where(round: round_num) }
  scope :for_deadline_type, ->(type_name) { joins(:deadline_type).where(deadline_types: { name: type_name }) }

  # Check if this deadline has passed
  def overdue?
    due_at < Time.current
  end

  # Check if this deadline is upcoming
  def upcoming?
    due_at > Time.current
  end

  def set(deadline_type_id, parent_id, round)
    self.deadline_type_id = deadline_type_id
    self.parent_id = parent_id
    self.round = round
    save!
  end

  def copy(to_assignment_id)
    to_assignment = Assignment.find(to_assignment_id)
    new_due_date = dup
    new_due_date.parent = to_assignment
    new_due_date.save!
    new_due_date
  end

  # Get the deadline type name
  def deadline_type_name
    deadline_type&.name
  end

  # Check if this is the last deadline for the parent
  def last_deadline?
    parent.due_dates.where('due_at > ?', due_at).empty?
  end

  # Comparison method for sorting
  def <=>(other)
    return nil unless other.is_a?(DueDate)

    due_at <=> other.due_at
  end

  # String representation
  def to_s
    "#{deadline_type_name} - Due #{due_at.strftime('%B %d, %Y at %I:%M %p')}"
  end

  # Class methods for collection operations
  class << self
    # Sort a collection of due dates chronologically
    def sort_due_dates(due_dates)
      due_dates.sort_by(&:due_at)
    end

    # Check if any due dates in the future exist for a collection
    def any_future_due_dates?(due_dates)
      due_dates.any?(&:upcoming?)
    end

    def copy(from_assignment_id, to_assignment_id)
      from_assignment = Assignment.find(from_assignment_id)
      to_assignment = Assignment.find(to_assignment_id)

      from_assignment.due_dates.each do |due_date|
        new_due_date = due_date.dup
        new_due_date.parent = to_assignment
        new_due_date.save!
      end
    end
  end

  private

  def due_at_is_valid_datetime
    return unless due_at.present?

    return if due_at.is_a?(Time) || due_at.is_a?(DateTime)

    errors.add(:due_at, 'must be a valid datetime')
  end

  # Set default round if not specified
  before_save :set_default_round

  def set_default_round
    self.round ||= 1
  end
end
