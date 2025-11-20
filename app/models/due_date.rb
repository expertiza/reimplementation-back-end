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

  # TODO: These attributes appear to represent whether each action is allowed for this deadline.
  #       But these are NOT persisted in DB.  
  #       → Verify if they should be real DB columns.
  attr_accessor :teammate_review_allowed, :submission_allowed, :review_allowed

  # TODO: This validator may be unnecessary because Rails supports datetime validation declaratively.
  #       Investigate replacing this with a standard validation or `validates_timeliness`.
  def due_at_is_valid_datetime
    errors.add(:due_at, 'must be a valid datetime') unless due_at.is_a?(Time)
  end

  # Method to compare due dates
  def <=>(other)
    due_at <=> other.due_at
  end

  # TODO: This only sorts an array and is fine.
  #       But we likely don't need this method because DB queries can order by due_at.
  def self.sort_due_dates(due_dates)
    due_dates.sort_by(&:due_at)
  end

  # TODO: BAD DESIGN — DueDate should NOT know how to fetch due dates from parent.
  #       Fetching due dates MUST be done inside Assignment or ProjectTopic.
  #       → This method will be removed after moving logic to Assignment#due_dates.
  def self.fetch_due_dates(parent_id)
    due_dates = where('parent_id = ?', parent_id)
    sort_due_dates(due_dates)
  end

  # TODO: Should accept a list of due dates as an argument
  #       instead of re-querying by parent_id.
  #       Example new signature:
  #          def self.next_due_date(due_dates)
  #            due_dates.min_by(&:due_at)
  #          end
  #
  #       Current design violates Single Responsibility.
  def self.next_due_date(parent_id)
    due_dates = fetch_due_dates(parent_id)
    due_dates.find { |due_date| due_date.due_at > Time.zone.now }
  end

  # TODO: This method is fine (operates only on due date objects),
  #       BUT it should not be responsible for fetching them.
  #       Accept due_dates array as argument instead.
  def self.any_future_due_dates?(due_dates)
    due_dates.any? { |due_date| due_date.due_at > Time.zone.now }
  end

  # TODO: This is basically an initialization step.
  #       Should NOT live here — should be handled by Assignment or a factory.
  #       Also violates SRP because DueDate is deciding how assignment uses deadlines.
  def set(deadline, assignment_id, max_round)
    self.deadline_type_id = deadline
    self.parent_id = assignment_id
    self.round = max_round
    save
  end

  # TODO: Same problem — eliminates need for fetch_due_dates entirely.
  #       After refactoring, Assignment should already hold due_dates in memory:
  #
  #          class Assignment
  #            def next_due_date
  #              due_dates.order(:due_at).first
  #            end
  #          end
  #
  #       So this DueDate class method will no longer query DB.
  def self.next_due_date(parent_id)
    due_dates = fetch_due_dates(parent_id)
    due_dates.find { |due_date| due_date.due_at > Time.zone.now }
  end

  # TODO: This is too ambiguous — name suggests copying a SET of due dates
  #       but actually duplicates only one.
  #       Will be moved to Assignment:
  #
  #          def copy_due_dates_to(new_assignment)
  #            due_dates.each { |d| d.duplicate_to_parent(new_assignment.id) }
  #          end
  #
  #       Rename here to avoid confusion: duplicate_to_parent or clone_for_parent
  def copy(new_assignment_id)
    new_due_date = dup
    new_due_date.parent_id = new_assignment_id

    # TODO: If new Assignment design stores additional metadata for deadlines,
    #       ensure they are copied here.
    new_due_date.save
  end
end

# ==============================================================================
# 1. MOVE ALL "DUE DATE FETCHING" LOGIC OUT OF THIS FILE
# ==============================================================================
# Problem:
#   - Methods like `fetch_due_dates(parent_id)` and `next_due_date(parent_id)`
#     require DueDate to know how Assignments or Topics store deadlines.
#   - This violates Single Responsibility and increases cross-class coupling.
#
# Required Fix:
#   - Delete `fetch_due_dates` entirely.
#   - Delete the version of `next_due_date` that accepts `parent_id`.
#   - Instead, Assignment (and possibly ProjectTopic) must define:
#
#         def due_dates
#           DueDate.where(parent: self)
#         end
#
#         def next_due_date
#           due_dates.order(:due_at).first
#         end
#
#   - After refactoring, DueDate class methods must operate ONLY on
#     *collections of DueDate objects*, not on parent objects.
#
# Benefit:
#   - Prevents DueDate from depending on Assignment internals.
#   - Clarifies that each "parent" object is responsible for retrieving its own deadlines.



# ==============================================================================
# 2. CREATE A NEW MIX-IN: DueDateActions (used by Assignment & ProjectTopic)
# ==============================================================================
# Problem:
#   - The system needs a clean way to determine whether a user can perform
#     an activity at the current time (submit, review, teammate_review, etc.).
#   - Currently there is no unified mechanism to check
#       "Is this activity allowed at this time?"
#   - Logic must NOT live in DueDate.rb (not its responsibility).
#
# Required Fix:
#   - Create file: app/models/concerns/due_date_actions.rb
#   - Implement:
#
#         module DueDateActions
#           def activity_permissible?(activity)
#             nd = next_due_date
#             return false unless nd
#             nd.public_send("#{activity}_allowed")
#           end
#
#           # syntactic sugar (no duplication)
#           def submission_permissible?
#             activity_permissible?(:submission)
#           end
#
#           def review_permissible?
#             activity_permissible?(:review)
#           end
#
#           def teammate_review_permissible?
#             activity_permissible?(:teammate_review)
#           end
#         end
#
#   - Then include this in Assignment.rb (and possibly ProjectTopic.rb):
#
#         include DueDateActions
#
# Benefit:
#   - Provides one place to define "time-based permission logic".
#   - Prevents repeated boilerplate methods.
#   - Clean API: assignment.submission_permissible?



# ==============================================================================
# 3. MOVE THE "COPYING MULTIPLE DUE DATES" LOGIC INTO Assignment
# ==============================================================================
# Problem:
#   - DueDate#copy duplicates only a single due date,
#     but real usage requires duplicating *all* due dates when copying an assignment.
#   - Currently, responsibility is incorrectly placed inside DueDate#copy.
#   - The method name `copy` is misleading (implies copying a collection).
#
# Required Fix:
#   - Keep DueDate responsible ONLY for cloning one instance:
#
#         def duplicate_to_parent(new_parent_id)
#           new = dup
#           new.parent_id = new_parent_id
#           new.save
#         end
#
#   - Move the loop for copying all due dates into Assignment:
#
#         def copy_due_dates_to(new_assignment)
#           due_dates.each do |due|
#             due.duplicate_to_parent(new_assignment.id)
#           end
#         end
#
# Benefit:
#   - Assignment knows it owns a set of due dates → SRP respected.
#   - Code becomes easier to maintain and avoids hidden cross-class dependencies.



################################################################################
# After completing these refactorings:
#   - DueDate.rb will represent ONLY the structure + behavior of ONE deadline.
#   - Assignment / ProjectTopic will manage collections of deadlines.
#   - DueDateActions mix-in will manage time-based permission logic.
################################################################################


################################################################################
# TODO (DB MIGRATIONS REQUIRED)
################################################################################

# 1) Create `deadline_types` table.
#    - Add table with :name, :description; make due_dates.deadline_type_id a FK.

# 2) Persist allowed-activity fields in DB.
#    - Add boolean columns to due_dates: :submission_allowed, :review_allowed,
#      :teammate_review_allowed (default false).

# 3) Audit due_dates schema consistency.
#    - Re-check round, parent_id, deadline_type_id after refactor to ensure
#      creation logic moves to Assignment/factories cleanly.