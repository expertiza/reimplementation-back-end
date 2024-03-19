# frozen_string_literal: true
class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper
  include ResponseHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer'
  
  validates :map_id, presence: true
  def validate(params, action)
    if action == 'create'
      self.map_id = params[:map_id]
    else
      self.map_id = self.response_map.id
    end
    response_map = ResponseMap.includes(:responses).find_by(id: self.map_id)
    if self.response_map.nil?
      errors.add(:response_map, 'Not found response map')
      return
    end

    self.response_map = response_map
    self.round = params[:response][:round] if params[:response]&.key?(:round)
    self.additional_comment = params[:response][:comments] if params[:response]&.key?(:comments)
    self.version_num = params[:response][:version_num] if params[:response]&.key?(:version_num)

    if action == 'create'
      if self.round.present? &&  self.version_num.present?
        existing_response = response_map.responses.where("map_id = ? and round = ? and version_num = ?", self.map_id, self.round, self.version_num).first
      elsif self.round.present? && !self.version_num.present?
        existing_response = response_map.responses.where("map_id = ? and round = ?", self.map_id, self.round).first
      elsif !self.round.present? && self.version_num.present?
        existing_response = response_map.responses.where("map_id = ? and version_num = ?", self.map_id, self.version_num).first
      end
      
      if existing_response.present?
        self.errors.add('response', 'Already existed.')
        return
      end
    elsif action == 'update'
      if self.is_submitted
        self.errors.add('response', "Already submitted.")
        return
      end
    end
    self.is_submitted = params[:response][:is_submitted] if params[:response]&.key?(:is_submitted)
  end

  def set_content(params, action)
    self.response_map = ResponseMap.find(map_id)
    if self.response_map.nil?
      self.errors.add(:response_map, ' Not found response map')
    else
      self
    end
    questions = get_questions(self)
    self.scores = get_answers(self, questions)
    self
  end
  def serialize_response
    {
      id: id,
      map_id: map_id,
      additional_comment: additional_comment,
      is_submitted: is_submitted,
      version_num: version_num,
      round: round,
      visibility: visibility,
      response_map: {
        id: response_map.id,
        reviewed_object_id: response_map.reviewed_object_id,
        reviewer_id:response_map.reviewer_id,
        reviewee_id: response_map.reviewee_id,
        type: response_map.type,
        calibrate_to: response_map.calibrate_to,
        team_reviewing_enabled: response_map.team_reviewing_enabled,
        assignment_questionnaire_id: response_map.assignment_questionnaire_id
      },
      scores: scores.map do |score|
        {
          id: score.id,
          answer: score.answer,
          comments: score.comments,
          question_id: score.question_id,
          question: {
            id: score.question.id,
            txt: score.question.txt,
            type: score.type,
            seq: score.seq,
            questionnaire_id: score.question_id
          }
        }
      end
    }.to_json
  end

  private
  
  
end





