# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper
  include ResponseHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map
  
  def validate(params, action)
    self.map_id = if action == 'create'
                    params[:map_id]
                  else
                    response_map.id
                  end
    response_map = ResponseMap.includes(:responses).find_by(id: map_id)
    if self.response_map.nil?
      errors.add(:response_map, 'Not found response map')
      return
    end

    self.response_map = response_map
    self.round = params[:response][:round] if params[:response]&.key?(:round)
    self.additional_comment = params[:response][:comments] if params[:response]&.key?(:comments)
    self.version_num = params[:response][:version_num] if params[:response]&.key?(:version_num)

    if action == 'create'
      if round.present? && version_num.present?
        existing_response = response_map.responses.where('map_id = ? and round = ? and version_num = ?', map_id,
                                                         round, version_num).first
      elsif round.present? && !version_num.present?
        existing_response = response_map.responses.where('map_id = ? and round = ?', map_id, round).first
      elsif !round.present? && version_num.present?
        existing_response = response_map.responses.where('map_id = ? and version_num = ?', map_id,
                                                         version_num).first
      end

      if existing_response.present?
        errors.add('response', 'Already existed.')
        return
      end
    elsif action == 'update'
      if is_submitted
        errors.add('response', 'Already submitted.')
        return
      end
    end
    self.is_submitted = params[:response][:is_submitted] if params[:response]&.key?(:is_submitted)
  end

  def set_content(_params, _action)
    self.response_map = ResponseMap.find(map_id)
    if response_map.nil?
      errors.add(:response_map, ' Not found response map')
    else
      self
    end
    questions = get_questions(self)
    self.scores = get_answers(self, questions)
    self
  end

  def serialize_response
    {
      id:,
      map_id:,
      additional_comment:,
      is_submitted:,
      version_num:,
      round:,
      visibility:,
      response_map: {
        id: response_map.id,
        reviewed_object_id: response_map.reviewed_object_id,
        reviewer_id: response_map.reviewer_id,
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
end
