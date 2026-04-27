# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  alias map response_map
  delegate :response_assignment, :reviewee, :reviewer, to: :map

  # return the questionnaire that belongs to the response
  def questionnaire
    response_assignment.assignment_questionnaires.find_by(used_in_round: self.round).questionnaire
  end

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

    # This score has already skipped the unfilled scorable item(s)
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

  # Returns the Answer this response recorded for a specific rubric item, or
  # nil if no answer was given. Centralises item-lookup here (Information Expert)
  # so callers don't scatter `scores.find { |a| a.item_id == item.id }` everywhere.
  def answer_for(item)
    scores.find { |a| a.item_id == item.id }
  end

  # Ordered rubric items used for this response, or [] if the rubric cannot be
  # resolved (e.g. no AssignmentQuestionnaire for this round). Belongs here
  # rather than in a controller because the response knows which questionnaire
  # applies to it.
  def rubric_items
    questionnaire.items.order(:seq)
  rescue NoMethodError
    []
  end

  # JSON representation of this response for calibration reports. Keeps the
  # serialization next to the class that owns the data (Information Expert),
  # so any consumer that needs a response rendered for a calibration view can
  # ask the response for it.
  def as_calibration_json
    {
      id: id,
      map_id: map_id,
      reviewer_id: map.reviewer_id,
      reviewer_name: map.reviewer&.fullname,
      is_submitted: is_submitted,
      updated_at: updated_at,
      answers: scores.map do |answer|
        {
          item_id: answer.item_id,
          score: answer.answer,
          comments: answer.comments
        }
      end
    }
  end

  # Returns the maximum possible score for this response
  def maximum_score
    # only count the scorable questions, only when the answer is not nil (we accept nil as
    # answer for scorable questions, and they will not be counted towards the total score)
    total_weight = 0
    scores.each do |s|
      total_weight += s.item.weight unless s.answer.nil? #|| !s.item.is_a(ScoredItem)?
    end
    total_weight * questionnaire.max_question_score
  end
end