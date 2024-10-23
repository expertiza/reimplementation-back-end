class DueDate < ApplicationRecord
  include Comparable
  # Named constants for teammate review statuses
  ALLOWED = 3
  LATE_ALLOWED = 2
  NOT_ALLOWED = 1

  belongs_to :parent, polymorphic: true
  validate :due_at_is_valid_datetime
  validates :due_at, presence: true

  attr_accessor :teammate_review_allowed_id, :submission_allowed_id, :review_allowed_id

  def due_at_is_valid_datetime
    errors.add(:due_at, 'must be a valid datetime') unless due_at.is_a?(Time)
  end

  # Method to compare due dates
  def <=>(other)
    self.due_at <=> other.due_at
  end

  # Return the set of due dates sorted by due_at
  def self.sort_due_dates(due_dates)
    due_dates.sort_by(&:due_at)
  end
  
  # Class method to return the next due date out of the set
  def self.next_due_date(due_dates)
    due_dates.find { |due_date| due_date.due_at > Time.zone.now }
  end

  # Class method to check if any due date is in the future
  def self.any_future_due_dates?(due_dates)
    due_dates.any? { |due_date| due_date.due_at > Time.zone.now }
  end

  def set(deadline, assign_id, max_round)
    self.deadline_type_id = deadline
    self.parent_id = assign_id
    self.round = max_round
    save
  end

  def self.copy(due_dates, new_assignment_id)
    due_dates.each do |orig_due_date|
      new_due_date = orig_due_date.dup
      new_due_date.parent_id = new_assignment_id
      new_due_date.save
    end
  end

  # factory method for retrieving due dates based on type of the parent
  def self.get_next_due_date
    case self.parent_type
    when 'Assignment'
      self.next_due_date(AssignmentDueDate.get_due_dates(self.parent_id))
    when 'ProjectTopic'
      self.next_due_date(TopicDueDate.get_due_dates(self.parent_id.assignment, self.parent_id))
    end
  end

end