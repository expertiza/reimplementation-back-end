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

  # returns a string of response name, needed so the front end can tell students which rubric they are filling out
  def rubric_label
    return 'Response' if map.nil?

    if map.respond_to?(:response_map_label)
      label = map.response_map_label
      return label if label.present?
    end

    # response type doesn't exist
    'Unknown Type'
  end

  # Returns true if this response's score differs from peers by more than the assignment notification limit
  def reportable_difference?
    map_class = map.class
    # gets all responses made by a reviewee
    existing_responses = map_class.assessments_for(map.reviewee)

  count = 0
  total_numerator = BigDecimal('0')
  total_denominator = BigDecimal('0')
    # gets the sum total percentage scores of all responses that are not this response
    # (each response can omit questions, so maximum_score may differ and we normalize before averaging)
    existing_responses.each do |response|
      unless id == response.id # the current_response is also in existing_responses array
        count += 1
        # Accumulate raw sums and divide once to minimize rounding error
        total_numerator += BigDecimal(response.aggregate_questionnaire_score.to_s)
        total_denominator += BigDecimal(response.maximum_score.to_s)
      end
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

  # Computes the total points earned for all answers on this response.
  #
  # For regular peer-review responses, each {Answer} contributes
  # <tt>answer.answer * item.weight</tt> when the numeric answer is non-nil.
  #
  # For quiz responses (identified by +reviewer_id == reviewee_id+ on the
  # associated {ResponseMap}), quiz item types store the student's selection
  # in the +comments+ column rather than the numeric +answer+ column.
  # These items are scored by case-insensitive string equality against
  # {Item#correct_answer}; a correct answer awards <tt>item.weight</tt> points
  # and an incorrect/blank answer awards 0.
  #
  # Supported quiz item types (both spaced and CamelCase variants are
  # accepted because the frontend historically used both conventions):
  # * <tt>"Text field"</tt> / <tt>"TextField"</tt>
  # * <tt>"Multiple choice"</tt> / <tt>"MultipleChoiceRadio"</tt>
  # * <tt>"Multiple choice checkbox"</tt> / <tt>"MultipleChoiceCheckbox"</tt>
  #
  # @return [Integer] the total raw score earned across all answers
  def aggregate_questionnaire_score
    # only count the scorable items, only when the answer is not nil
    # we accept nil as answer for scorable items, and they will not be counted towards the total score
    sum = 0
    # E2619: quiz maps are identified by reviewer_id == reviewee_id (the student reviews
    # themselves). The response_maps table has no STI type column so is_a?(QuizResponseMap)
    # always returns false; this is the only reliable discriminator.
    is_quiz = map.reviewer_id == map.reviewee_id
    # E2619: The frontend stores question types with spaces ("Text field", "Multiple choice",
    # "Multiple choice checkbox"). Include both the spaced and CamelCase variants so scoring
    # works regardless of which convention was used when the quiz was created.
    comment_scored_types = %w[
      TextField MultipleChoiceRadio MultipleChoiceCheckbox
      Text\ field Multiple\ choice Multiple\ choice\ checkbox
    ].freeze
    scores.each do |s|
      # E2619: TextField, MultipleChoiceRadio, and MultipleChoiceCheckbox quiz items put
      # the student's selected/typed answer into the comments column (answer is null).
      # Score them by case-insensitive equality against item.correct_answer.
      if is_quiz && comment_scored_types.include?(s.item.question_type)
        correct = s.item.correct_answer.to_s.strip.downcase
        student_answer = s.comments.to_s.strip.downcase
        sum += (student_answer == correct && correct.present? ? 1 : 0) * (s.item.weight || 1)
      else
        sum += s.answer * (s.item.weight || 1) unless s.answer.nil?
      end
    end
    sum
  end

  # Returns the maximum possible score for this response.
  #
  # For regular peer-review responses, only answers whose numeric +answer+
  # field is non-nil contribute to the maximum, mirroring the behaviour of
  # {#aggregate_questionnaire_score}.
  #
  # For quiz responses (identified by +reviewer_id == reviewee_id+ on the
  # associated {ResponseMap}), comment-scored item types (see
  # {#aggregate_questionnaire_score}) always contribute to the maximum
  # regardless of whether the student provided an answer, because quiz items
  # never populate the numeric +answer+ column.
  #
  # The total accumulated weight is multiplied by the questionnaire's
  # +max_question_score+ to obtain the ceiling score.
  #
  # @return [Integer] the maximum achievable score for this response
  def maximum_score
    total_weight = 0
    # E2619: same quiz discriminator as aggregate_questionnaire_score.
    is_quiz = map.reviewer_id == map.reviewee_id
    comment_scored_types = %w[
      TextField MultipleChoiceRadio MultipleChoiceCheckbox
      Text\ field Multiple\ choice Multiple\ choice\ checkbox
    ].freeze
    scores.each do |s|
      # E2619: comment-based quiz items have a null answer but still occupy a scoring slot,
      # so they must be counted in the maximum regardless of whether the student answered.
      if is_quiz && comment_scored_types.include?(s.item.question_type)
        total_weight += (s.item.weight || 1)
      else
        total_weight += (s.item.weight || 1) unless s.answer.nil?
      end
    end
    total_weight * questionnaire.max_question_score
  end
end