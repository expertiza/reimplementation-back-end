# frozen_string_literal: true

module Reports
  # Reports::ReportTemplate is the Template Method skeleton shared by every
  # report in the system (review, author-feedback, teammate, bookmark,
  # calibration, survey, quiz).
  #
  # It defines the fixed algorithm: setup → iterate one response at a time →
  # assemble the payload. Subclasses fill in each step without altering the
  # overall sequence.
  #
  # Two design rules drive what does -- and does not -- live here:
  #
  # 1. Iterate over responses, never preload them into an ad-hoc array.
  #    Subclasses implement `each_response` as an *iterator* that yields one
  #    Response at a time. The template loops once and dispatches; nothing in
  #    the template ever needs the whole collection in memory.
  #
  # 2. No specific metrics in the template.
  #    Different reports want different summaries (averages for one, score
  #    histograms for another, per-tag counts for answer-tagging). The
  #    template therefore exposes only the skeleton -- setup, accumulate,
  #    payload -- and lets each subclass define its own state and metric logic.
  #
  # Subclass contract:
  #   * setup           -- prepare any state needed before iteration
  #                        (rubric items, output buffers, etc.). Optional.
  #   * each_response   -- yield Responses one at a time. REQUIRED.
  #   * accumulate(r)   -- update subclass-owned state from a single response.
  #                        REQUIRED.
  #   * payload         -- return the final JSON-ready Hash. REQUIRED.
  class ReportTemplate
    def render
      setup
      each_response { |response| accumulate(response) }
      payload
    end

    private

    def setup; end

    def each_response
      raise NotImplementedError, "#{self.class} must implement #each_response as an iterator"
    end

    def accumulate(_response)
      raise NotImplementedError, "#{self.class} must implement #accumulate(response)"
    end

    def payload
      raise NotImplementedError, "#{self.class} must implement #payload"
    end
  end
end
