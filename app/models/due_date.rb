# frozen_string_literal: true

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

  # Resolves the next submission deadline from generic domain inputs:
  # the assignment being worked on and an optional sign-up topic. This method
  # intentionally does not know about Response, ResponseMap, or controller
  # params. Callers are responsible for deriving the relevant assignment/topic
  # from their own context, then delegating deadline comparison here.
  #
  # That keeps DueDate reusable across controllers while still supporting the
  # current response flow, where topic-aware review deadlines may override the
  # assignment-level due date.
  def self.next_submission_due_date(assignment:, topic: nil)
    return nil unless assignment&.id

    return TopicDueDate.next_due_date(assignment.id, topic.id) if topic&.id

    next_due_date(assignment.id)
  end

  # Returns true when the relevant submission deadline has not yet passed.
  # The method is generic at the due-date layer: it answers "is submission
  # still open for this assignment/topic context?" rather than encoding any
  # response-specific behavior.
  def self.submission_window_open?(assignment:, topic: nil, reference_time: Time.current)
    return true unless assignment

    next_due = next_submission_due_date(assignment: assignment, topic: topic)
    next_due.nil? || next_due.due_at > reference_time
  end

  # Determines the current round for a parent (assignment/topic) using one consistent rule:
  # - If any round-based due dates are in the past, use the latest past due date's round.
  # - Otherwise, use the earliest upcoming due date's round.
  # - If no round-based due dates exist, return 0.
  def self.current_round_for(parent, reference_time: Time.current)
    return 0 unless parent&.id

    scoped = where(parent: parent).where.not(round: nil, due_at: nil)

    latest_past = scoped.where('due_at <= ?', reference_time).order(due_at: :desc).first
    return latest_past.round.to_i if latest_past

    earliest_upcoming = scoped.where('due_at > ?', reference_time).order(due_at: :asc).first
    return earliest_upcoming.round.to_i if earliest_upcoming

    0
  end

  # Creates duplicate due dates and assigns them to a new assignment
  def copy(new_assignment_id)
    new_due_date = dup
    new_due_date.parent_id = new_assignment_id
    new_due_date.save
  end
end
