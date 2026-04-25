# frozen_string_literal: true

class CalibrationPerItemSummary
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

  def build
    instructor_answers = answers_by_item(@instructor_response)
    latest_student_responses = latest_submitted_student_responses
    student_answers = latest_student_responses.to_h { |response| [response.id, answers_by_item(response)] }

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

  def latest_submitted_student_responses
    @student_responses
      .select(&:is_submitted)
      .group_by(&:map_id)
      .values
      .map { |responses| responses.max_by(&:updated_at) }
      .compact
  end

  def answers_by_item(response)
    return {} unless response

    response.scores.each_with_object({}) do |answer, by_item|
      by_item[answer.item_id] = answer
    end
  end

  def bucket_counts_for(item, responses, answers_by_response)
    buckets = score_range_for(item).each_with_object({}) do |score, counts|
      counts[score.to_s] = 0
    end

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
