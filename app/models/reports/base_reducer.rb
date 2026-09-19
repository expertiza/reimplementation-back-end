# frozen_string_literal: true

module Reports
  # Base class for streaming reducers.
  #
  # Runs a three-step pipeline: source → accumulate(state, row) → finalize(state).
  # The source relation is consumed via find_each so memory usage scales with
  # the number of output groups, not with the total number of source rows.
  # Each subclass owns its accumulate/finalize logic entirely; the base class
  # provides only the streaming scaffold and shared cross-cutting concerns
  # (batching, optional shared_state for multi-reducer coordination).
  #
  # Subclasses must implement (private):
  #   source                 → AR relation (consumed via find_each)
  #   initial_state          → empty accumulator value
  #   accumulate(state, row) → mutates state in place; all grouping and domain
  #                            math lives here, not in the base class.
  #
  # Subclasses may override (private):
  #   finalize(state) → transforms finished state into the output hash
  #                     (default: returns state unchanged)
  #
  # Replaces two anti-patterns from the naive approach:
  #   - Loading all rows into an unnamed array before processing (wastes memory).
  #   - Encoding domain metrics (e.g. avg_score) in the base class, which ties
  #     every reducer to one shape of math.
  class BaseReducer
    # Factory method for assignment-scoped reports.
    def self.for_assignment(assignment)
      new(assignment)
    end

    # Factory method for course-scoped reports.
    def self.for_course(course)
      new(course)
    end

    # @param reportable [Assignment, Course] the object the report is scoped to.
    # Subclasses reference @reportable instead of a type-specific variable so
    # the same reducer works for any reportable entity.
    def initialize(reportable)
      @reportable = reportable
    end

    # Runs the reducer: stream → accumulate → finalize.
    #
    # Accepts an optional shared_state so that multiple reducers can write
    # into the same hash without a merge loop. When shared_state is provided,
    # initial_state is ignored — the coordinator owns state initialization.
    # finalize is always called, even when shared_state is provided.
    #
    # Benefits of this structure over writing reducer code directly:
    #   1. Memory safety — find_each streams in batches of 500 rather than
    #      loading the entire relation into Ruby. Every report gets this for free.
    #   2. New reports are just data — subclasses define source/initial_state/
    #      accumulate/finalize; the reducer wiring is not their concern.
    #   3. Single place for cross-cutting concerns — logging, timing, or error
    #      handling can be added here once and applies to every report.
    def run(shared_state = nil)
      state = shared_state || initial_state
      source.find_each(batch_size: 500) do |row|
        accumulate(state, row)
      end
      finalize(state)
    end

    private

    def source        = raise NotImplementedError, "#{self.class}#source"
    def initial_state = raise NotImplementedError, "#{self.class}#initial_state"

    def accumulate(_state, _row)
      raise NotImplementedError, "#{self.class}#accumulate"
    end

    def finalize(state) = state
  end
end
