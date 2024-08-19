# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map

  def reportable_difference?
    map_class = map.class
    # gets all responses made by a reviewee
    existing_responses = map_class.assessments_for(map.reviewee)

    count = 0
    total = 0
    # gets the sum total percentage scores of all responses that are not this response
    existing_responses.each do |response|
      unless id == response.id # the current_response is also in existing_responses array
        count += 1
        total +=  response.aggregate_questionnaire_score.to_f / response.maximum_score
      end
    end

    # if this response is the only response by the reviewee, there's no grade conflict
    return false if count.zero?

    # calculates the average score of all other responses
    average_score = total / count

    # This score has already skipped the unfilled scorable question(s)
    score = aggregate_questionnaire_score.to_f / maximum_score
    questionnaire = questionnaire_by_answer(scores.first)
    assignment = map.assignment
    assignment_questionnaire = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: questionnaire.id)

    # notification_limit can be specified on 'Rubrics' tab on assignment edit page.
    allowed_difference_percentage = assignment_questionnaire.notification_limit.to_f

    # the range of average_score_on_same_artifact_from_others and score is [0,1]
    # the range of allowed_difference_percentage is [0, 100]
    (average_score - score).abs * 100 > allowed_difference_percentage
  end

  def aggregate_questionnaire_score
    # only count the scorable questions, only when the answer is not nil
    # we accept nil as answer for scorable questions, and they will not be counted towards the total score
    sum = 0
    scores.each do |s|
      question = Question.find(s.question_id)
      # For quiz responses, the weights will be 1 or 0, depending on if correct
      sum += s.answer * question.weight unless s.answer.nil? || !question.scorable?
    end
    sum
  end

  # Calculate score based on provided answers
  def calculate_score(params)
    questionnaire = Questionnaire.find(map.reviewed_object_id)
    questions = Question.where(questionnaire_id: questionnaire.id)
    valid = true
    scores = []

    questions.each do |question|
      score = score(question, params)
      new_score = Answer.new(
        comments: params[question.id.to_s],
        question_id: question.id,
        response_id: id,
        answer: score
      )

      valid = false unless new_score.valid?
      scores.push(new_score)
    end

    if valid
      scores.each(&:save)
      true
    else
      false
    end
  end

  # Calculates the score for a question based on the type and user answers.
  def score(question, user_answers)
    correct_answers = question.quiz_question_choices.where(iscorrect: true)

    case question.question_type
    when 'MultipleChoiceCheckbox'
      checkbox_score(correct_answers, user_answers)
    when 'TrueFalse', 'MultipleChoiceRadio'
      calculate_score_for_truefalse_question(correct_answers.first, user_answers)
    else
      0 # Default score for unsupported question types
    end
  end

  private

  # Calculates score for Checkbox type questions.
  def checkbox_score(correct_answers, user_answers)
    return 0 if user_answers.nil?

    score = 0
    correct_answers.each do |correct|
      score += 1 if user_answers.include?(correct.txt)
    end

    score == correct_answers.count && score == user_answers.count ? 1 : 0
  end

  # Calculates score for TrueFalse and MultipleChoice type questions.
  def truefalse_score(correct_answer, user_answer)
    correct_answer.txt == user_answer ? 1 : 0
  end
end
