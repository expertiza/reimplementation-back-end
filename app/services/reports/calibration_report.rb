# frozen_string_literal: true

module Reports
  # Reports::CalibrationReport renders the comparison view for one instructor
  # calibration map: the instructor's submitted response, the rubric items,
  # the (latest submitted) student peer responses for the same reviewee, and
  # a per-item bucket-count summary suitable for a stacked chart.
  #
  # Design notes (mirroring Reports::Base):
  #   * Responses are walked one-at-a-time via an iterator on
  #     ReviewResponseMap. We never build a giant Array of all peer responses
  #     in memory; we ask the model to yield the latest submitted Response
  #     for each peer calibration map.
  #   * The metric this report produces (per-item score histograms) lives
  #     here, NOT in the base, because other reports (averages, tag counts,
  #     survey aggregates) want completely different shapes.
  class CalibrationReport < BaseReport
    InstructorResponseMissing = Class.new(StandardError)
    RubricMissing             = Class.new(StandardError)

    def initialize(instructor_map)
      @instructor_map = instructor_map
    end

    private

    def setup
      @instructor_response = @instructor_map.latest_submitted_response
      raise InstructorResponseMissing, 'Submitted instructor calibration response not found' if @instructor_response.nil?

      @rubric_items = @instructor_response.rubric_items
      raise RubricMissing, 'Review rubric not found' if @rubric_items.empty?

      # @bucket_counts is a two-level Hash:
      #   { item_id => { "0" => count, "1" => count, ..., "N" => count } }
      # The inner Hash covers every integer in the questionnaire's score range so
      # the presenter always receives a complete histogram (zero-filled buckets
      # included) without needing to know the min/max score.
      @bucket_counts     = empty_buckets_for(@rubric_items)
      @student_responses = []
    end

    # Iterator: ask ReviewResponseMap for the latest submitted student
    # calibration Response per peer map and yield them one at a time.
    def each_response(&block)
      ReviewResponseMap.peer_calibration_responses_each(@instructor_map, &block)
    end

    # State updated per response. The metric here (score histograms) is
    # CalibrationReport-specific; that is exactly why it does not belong in
    # the base.
    def accumulate(response)
      @student_responses << response
      response.scores.each do |answer|
        next if answer.answer.nil?
        next unless @bucket_counts.key?(answer.item_id)

        bucket_key = answer.answer.to_i.to_s
        @bucket_counts[answer.item_id][bucket_key] ||= 0
        @bucket_counts[answer.item_id][bucket_key] += 1
      end
    end

    def payload
      {
        map_id:              @instructor_map.id,
        assignment_id:       @instructor_map.reviewed_object_id,
        reviewee_id:         @instructor_map.reviewee_id,
        rubric_items:        @rubric_items.map(&:as_calibration_json),
        instructor_response: @instructor_response.as_calibration_json,
        student_responses:   @student_responses.map(&:as_calibration_json),
        per_item_summary:    @rubric_items.sort_by(&:seq).map { |item| per_item_summary(item) },
        submitted_content:   submitted_content_for(@instructor_map.reviewee)
      }
    end

    def empty_buckets_for(items)
      items.each_with_object({}) do |item, hash|
        # Delegate the valid score range to the Questionnaire (Information Expert).
        # The fallback to class-level defaults lives in Questionnaire#score_range,
        # not here, so calibration code does not carry knowledge of score bounds.
        range = item.questionnaire&.score_range || (0..5)
        hash[item.id] = range.each_with_object({}) { |score, b| b[score.to_s] = 0 }
      end
    end

    def per_item_summary(item)
      instructor_answer = @instructor_response.answer_for(item)
      {
        item_id:                item.id,
        item_label:             item.txt,
        item_seq:               item.seq,
        instructor_score:       instructor_answer&.answer,
        instructor_comment:     instructor_answer&.comments,
        bucket_counts:          @bucket_counts[item.id],
        student_response_count: @student_responses.size
      }
    end

    def submitted_content_for(reviewee)
      return { hyperlinks: [], files: [] } unless reviewee.respond_to?(:submitted_content)
      reviewee.submitted_content
    end
  end
end
