# frozen_string_literal: true

module Reports
  # Template for a streaming reduce-based report pipeline.
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
  #   This class contains *only* the pipeline scaffold; each subclass owns its
  #   accumulate/finalize logic entirely.
  #
  # Subclasses must implement (private):
  #   source        → AR relation (consumed via find_each)
  #   grouper       → lambda(row) → grouping key
  #   initial_state → empty accumulator value
  #   accumulate(state, key, row)  → mutates state in place
  #
  # Subclasses may override (private):
  #   finalize(state) → transforms finished state into the output hash
  #                      (default: returns state unchanged)
  class BaseReport
    def initialize(assignment)
      @assignment = assignment
    end

    def run
      state = initial_state
      source.find_each(batch_size: 500) do |row|
        accumulate(state, grouper.call(row), row)
      end
      finalize(state)
    end

    private

    def source        = raise NotImplementedError, "#{self.class}#source"
    def grouper       = raise NotImplementedError, "#{self.class}#grouper"
    def initial_state = raise NotImplementedError, "#{self.class}#initial_state"

    def accumulate(_state, _key, _row)
      raise NotImplementedError, "#{self.class}#accumulate"
    end

    def finalize(state) = state
  end
end
