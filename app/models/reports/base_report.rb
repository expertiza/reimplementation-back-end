# frozen_string_literal: true

module Reports
  # Template for a streaming reduce-based report.
  #
  # Design rationale (addresses two anti-patterns from the naive approach):
  #
  #   Anti-pattern 1 — "fetch_responses": loading all records into an unnamed
  #   ad-hoc array before processing wastes memory and forces the entire result
  #   set into Ruby-land.  Instead, #run streams the source relation via
  #   find_each so memory usage scales with the number of *groups*, not rows.
  #
  #   Anti-pattern 2 — "default metrics in base": encoding avg_score or any
  #   domain metric in the base class ties every report to one shape of math.
  #   This class contains *only* the reducer scaffold; each subclass owns its
  #   accumulate/finalize logic entirely.
  #
  # Subclasses must implement (private):
  #   source        → AR relation (consumed via find_each)
  #   state_key_for → lambda(row) → state bucket key
  #                   Separates "what bucket does this row belong to?" from
  #                   "what do I do with a row in that bucket?" (accumulate).
  #                   BaseReport#run calls state_key_for.call(row) and passes the
  #                   result as the key to accumulate — subclasses get this
  #                   wiring for free and can see at a glance what each
  #                   reducer is aggregating over. Examples:
  #                     ScoresReducer          groups by reviewer_id — all responses
  #                       from the same reviewer go into the same bucket
  #                     AvgRangesReducer       groups by team_id — all review mappings
  #                       for the same team go into the same bucket
  #                     TaggableAnswersReducer groups by team_id     — all answers
  #                       received by the same team go into the same bucket
  #   initial_state → empty accumulator value
  #   accumulate(state, key, row)  → mutates state in place; key is the result
  #                   of state_key_for.call(row). Answers "what do I do with a row
  #                   in this bucket?" — all domain math lives here, not in
  #                   the base class. Note: BaseReport passes the key but does not
  #                   enforce that accumulate uses it — subclasses are trusted to
  #                   use it as the state bucket key; using a different key silently
  #                   breaks the grouping contract.
  #
  # Subclasses may override (private):
  #   finalize(state) → transforms finished state into the output hash
  #                      (default: returns state unchanged)
  class BaseReport
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

    # Runs the reducer: stream → group → accumulate → finalize.
    #
    # Accepts an optional shared_state so that multiple reducers can write
    # into the same hash without a merge loop. When shared_state is provided,
    # initial_state is ignored — the coordinator owns state initialization.
    # finalize is always called, even when shared_state is provided.
    #
    # Benefits of this structure over writing report code directly:
    #   1. Memory safety — find_each streams in batches of 500 rather than
    #      loading the entire relation into Ruby. Every report gets this for free.
    #   2. New reports are just data — subclasses define source/state_key_for/accumulate/
    #      finalize; the reducer wiring is not their concern.
    #   3. Single place for cross-cutting concerns — logging, timing, or error
    #      handling can be added here once and applies to every report.
    def run(shared_state = nil)
      state = shared_state || initial_state
      source.find_each(batch_size: 500) do |row|
        accumulate(state, state_key_for.call(row), row)
      end
      finalize(state)
    end

    private

    def source        = raise NotImplementedError, "#{self.class}#source"
    def state_key_for       = raise NotImplementedError, "#{self.class}#state_key_for"
    def initial_state = raise NotImplementedError, "#{self.class}#initial_state"

    def accumulate(_state, _key, _row)
      raise NotImplementedError, "#{self.class}#accumulate"
    end

    def finalize(state) = state
  end
end
