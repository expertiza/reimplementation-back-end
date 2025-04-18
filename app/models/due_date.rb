class DueDate < ApplicationRecord
  include Comparable
  # Named constants for teammate review statuses
  ALLOWED = 3
  LATE_ALLOWED = 2
  NOT_ALLOWED = 1

  belongs_to :parent, polymorphic: true
  validate :due_at_is_valid_datetime
  validates :due_at, presence: true

  attr_accessor :teammate_review_allowed, :submission_allowed, :review_allowed

  def due_at_is_valid_datetime
    errors.add(:due_at, 'must be a valid datetime') unless due_at.is_a?(Time)
  end

  # Method to compare due dates
  def <=>(other)
    due_at <=> other.due_at
  end

  # Return the set of due dates sorted by due_at
  def self.sort_due_dates(due_dates)
    due_dates.sort_by(&:due_at)
  end

  # Fetches all due dates for the parent Assignment or Topic
  def self.fetch_due_dates(parent_id)
    due_dates = where('parent_id = ?', parent_id)
    sort_due_dates(due_dates)
  end

  # Class method to check if any due date is in the future
  def self.any_future_due_dates?(due_dates)
    due_dates.any? { |due_date| due_date.due_at > Time.zone.now }
  end

  def set(deadline, assignment_id, max_round)
    self.deadline_type_id = deadline
    self.parent_id = assignment_id
    self.round = max_round
    save
  end

  # Fetches due dates from parent then selects the next upcoming due date
  def self.next_due_date(parent_id)
    due_dates = fetch_due_dates(parent_id)
    due_dates.find { |due_date| due_date.due_at > Time.zone.now }
  end

  # Creates duplicate due dates and assigns them to a new assignment
  def copy(new_assignment_id)
    new_due_date = dup
    new_due_date.parent_id = new_assignment_id
    new_due_date.save
  end

  def self.get_next_due_date(assignment_id, topic_id = nil)
    if Assignment.find(assignment_id).staggered_deadline?
      next_due_date = TopicDueDate.find_by(['parent_id = ? and due_at >= ?', topic_id, Time.zone.now])
      if next_due_date.nil?
        topic_due_date_size = TopicDueDate.where(parent_id: topic_id).size
        following_assignment_due_dates = AssignmentDueDate.where(parent_id: assignment_id)[topic_due_date_size..-1]
        unless following_assignment_due_dates.nil?
          following_assignment_due_dates.each do |assignment_due_date|
            if assignment_due_date.due_at >= Time.zone.now
              next_due_date = assignment_due_date
              break
            end
          end
        end
      end
    else
      next_due_date = AssignmentDueDate.find_by(['parent_id = ? && due_at >= ?', assignment_id, Time.zone.now])
    end
    next_due_date
  end
end
