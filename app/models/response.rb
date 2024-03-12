# frozen_string_literal: true
require 'response_helper'

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false
  
  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map

  def get_response_map_by_type(map_id)
    if response_map.type.present?
      response_map.type.classify.constantize(map_id)
    end
  end
  def aggregate_questionnaire_score
    # only count the scorable questions, only when the answer is not nil
    # we accept nil as answer for scorable questions, and they will not be counted towards the total score
    sum = 0
    scores.each do |s|
      question = Question.find(s.question_id)
      # For quiz responses, the weights will be 1 or 0, depending on if correct
      sum += s.answer * question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    sum
  end
  def questionnaire_by_answer(answer)
    if answer.nil?
      # there is small possibility that the answers is empty: when the questionnaire only have 1 question and it is a upload file question
      # the reason is that for this question type, there is no answer record, and this question is handled by a different form
      map = ResponseMap.find(map_id)
      # E-1973 either get the assignment from the participant or the map itself
      assignment = if map.is_a? ReviewResponseMap
                     map.assignment
                   else
                     Participant.find(map.reviewer_id).assignment
                   end
      questionnaire = Questionnaire.find(assignment.review_questionnaire_id)
    else # for all the cases except the case that  file submission is the only question in the rubric.
      questionnaire = Question.find(answer.question_id).questionnaire
    end
    questionnaire
  end
end





