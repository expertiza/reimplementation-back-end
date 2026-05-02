# frozen_string_literal: true

# CalibrationPerItemSummary builds a per-rubric-item summary (score buckets +
# instructor score) from a pre-fetched collection of Response objects.
#
# NOTE: This class is superseded for the HTTP report endpoint by
# Reports::CalibrationReport, which uses an iterator-based pipeline
# (Template Method pattern) so responses are never bulk-loaded into memory.
# CalibrationPerItemSummary is retained for use by the calibration demo rake
# task (lib/tasks/calibration_demo.rake), which works with small in-memory
# arrays and does not need the streaming approach.
class CalibrationPerItemSummary
  # Convenience factory: constructs an instance and immediately calls build.
  # Equivalent to `new(...).build`.
  def self.build(items:, instructor_response:, student_responses:)
    new(
      items: items,
      instructor_response: instructor_response,
      student_responses: student_responses
    ).build
  end

  def initialize(items:, instructor_response:, student_responses:)
    @items = Array(items)
    @instructor_response = instructor_response
    @student_responses = Array(student_responses).compact
  end

  # Returns an Array of per-item summary hashes sorted by item sequence number.
  # Each hash contains the instructor score, instructor comment, per-score
  # bucket counts, and the number of student responses that contributed.
  def build
    instructor_answers = answers_by_item(@instructor_response)
    latest_student_responses = latest_submitted_student_responses
    student_answers = latest_student_responses.to_h { |response| [response.id, answers_by_item(response)] }

    # Sort by seq so the caller receives items in rubric display order.
    @items.sort_by(&:seq).map do |item|
      {
        item_id: item.id,
        item_label: item.txt,
        item_seq: item.seq,
        instructor_score: instructor_answers[item.id]&.answer,
        instructor_comment: instructor_answers[item.id]&.comments,
        bucket_counts: bucket_counts_for(item, latest_student_responses, student_answers),
        student_response_count: latest_student_responses.count
      }
    end
  end

  private

  # For each calibration map, keep only the most recently updated submitted
  # response. Older submitted versions and any drafts are discarded.
  def latest_submitted_student_responses
    @student_responses
      .select(&:is_submitted)
      .group_by(&:map_id)
      .values
      .map { |responses| responses.max_by(&:updated_at) }
      .compact
  end

  # Returns a Hash mapping item_id → Answer for all answers in the response,
  # or {} when the response is nil (e.g. instructor has no response yet).
  def answers_by_item(response)
    return {} unless response

    response.scores.each_with_object({}) do |answer, by_item|
      by_item[answer.item_id] = answer
    end
  end

  # Tallies how many student responses scored each possible value for `item`.
  # Returns a Hash of { score_string => count } covering every integer in the
  # questionnaire's min..max range so the caller always gets a full histogram.
  def bucket_counts_for(item, responses, answers_by_response)
    buckets = score_range_for(item).each_with_object({}) do |score, counts|
      counts[score.to_s] = 0
    end

    # `responses` is already reduced to the latest submitted response for each
    # student calibration map, so this counts one effective calibration review
    # per reviewer for the shared calibration artifact.
    responses.each do |response|
      score = answers_by_response.fetch(response.id).fetch(item.id, nil)&.answer
      next if score.nil?

      key = score.to_i.to_s
      buckets[key] ||= 0
      buckets[key] += 1
    end

    buckets
  end

  def score_range_for(item)
    min_score = item.questionnaire&.min_question_score || 0
    max_score = item.questionnaire&.max_question_score || 5

    min_score.to_i..max_score.to_i
  end
end
