# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false
  accepts_nested_attributes_for :scores

  alias map response_map
  delegate :response_assignment, :reviewee, :reviewer, to: :map

  # return the questionnaire that belongs to the response
  def questionnaire
    response_assignment.assignment_questionnaires.find_by(used_in_round: self.round).questionnaire
  end

  # Backward-compatible wrapper around ResponseMap#response_map_label.
  # Keep this on Response so callers do not need to dereference map directly.
  def rubric_label
    return 'Response' if map.nil?

    label = map.response_map_label
    return label if label.present?

    # response type doesn't exist
    'Unknown Type'
  end

  # Returns true if this response's score differs from peers by more than the assignment notification limit
  # This comparison is response-specific (uses per-response max score and questionnaire settings),
  # so it stays on Response instead of the generic ReviewAggregator mixin.
  def reportable_difference?
    map_class = map.class
    # gets all responses made by a reviewee
    existing_responses = map_class.assessments_for(map.reviewee)

    count = 0
    total_numerator = BigDecimal('0')
    total_denominator = BigDecimal('0')
    # gets the sum total percentage scores of all responses that are not this response
    # (each response can omit questions, so maximum_score may differ and we normalize before averaging)
    existing_responses.each do |peer_response|
      next if id == peer_response.id # this response may also be present in existing_responses

      count += 1
      # Accumulate raw sums and divide once to minimize rounding error
      total_numerator += BigDecimal(peer_response.aggregate_questionnaire_score.to_s)
      total_denominator += BigDecimal(peer_response.maximum_score.to_s)
    end

    # if this response is the only response by the reviewee, there's no grade conflict
    return false if count.zero?

    # Calculate average of peers by dividing once at the end
    average_score = if total_denominator.zero?
                      0.0
                    else
                      (total_numerator / total_denominator).to_f
                    end

    # This score has already skipped the unfilled scorable item(s)
    # Normalize this response similarly, dividing once
    this_numerator = BigDecimal(aggregate_questionnaire_score.to_s)
    this_denominator = BigDecimal(maximum_score.to_s)
    score = if this_denominator.zero?
              0.0
            else
              (this_numerator / this_denominator).to_f
            end
    questionnaire = questionnaire_by_answer(scores.first)
    assignment = map.assignment
    assignment_questionnaire = AssignmentQuestionnaire.find_by(assignment_id: assignment.id,
                                                               questionnaire_id: questionnaire.id)

    # notification_limit can be specified on 'Rubrics' tab on assignment edit page.
    allowed_difference_percentage = assignment_questionnaire.notification_limit.to_f

    # the range of average_score_on_same_artifact_from_others and score is [0,1]
    # the range of allowed_difference_percentage is [0, 100]
    (average_score - score).abs * 100 > allowed_difference_percentage
  end

  def aggregate_questionnaire_score
    # only count the scorable items, only when the answer is not nil
    # we accept nil as answer for scorable items, and they will not be counted towards the total score
    sum = 0
    scores.each do |s|
      # For quiz responses, the weights will be 1 or 0, depending on if correct
      sum += s.answer * s.item.weight unless s.answer.nil?  #|| !s.item.scorable?
    end
    # puts "sum: #{sum}"
    sum
  end

  # Returns the maximum possible score for this response
  def maximum_score
    # only count the scorable questions, only when the answer is not nil (we accept nil as
    # answer for scorable questions, and they will not be counted towards the total score)
    total_weight = 0
    scores.each do |s|
      total_weight += s.item.weight unless s.answer.nil? #|| !s.item.is_a(ScoredItem)?
    end
    # puts "total: #{total_weight * questionnaire.max_question_score} "
    total_weight * questionnaire.max_question_score
  end
end
