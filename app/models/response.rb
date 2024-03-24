# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper
  include ResponseHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map

  # Validates parameters for creating or updating a response. The method checks for the presence and validity
  # of the response map and specific fields based on the action (create or update). It ensures that
  # new responses do not duplicate existing ones and that updates are not made to already submitted responses.
  #
  # @param params [Hash] The parameters to be validated.
  # @param action [String] Specifies the action, either 'create' or 'update'.
  def validate_params(params, action)
    self.map_id = if action == 'create'
                    params[:map_id]
                  else
                    response_map.id
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
      if self.round.present? && self.version_num.present?
        existing_response = response_map.responses.where('map_id = ? and round = ? and version_num = ?', self.map_id,
                                                         self.round, self.version_num).first
      elsif round.present? && !version_num.present?
        existing_response = response_map.responses.where('map_id = ? and round = ?', self.map_id, round).first
      elsif !round.present? && version_num.present?
        existing_response = response_map.responses.where('map_id = ? and version_num = ?', self.map_id,
                                                         self.version_num).first
      end

      if existing_response.present?
        self.errors.add('response', 'Already existed.')
        return
      end
    elsif action == 'update'
      if is_submitted
        self.errors.add('response', 'Already submitted.')
        return
      end
    end
    self.is_submitted = params[:response][:is_submitted] if params[:response]&.key?(:is_submitted)
  end

  # Prepares the response object with necessary content including generating answer objects
  # for each question associated with the response. This method retrieves the questionnaire and its questions
  # for the current response, generating a new Answer object for each question if one doesn't already exist.
  def set_content
    self.response_map = ResponseMap.find(map_id)
    if response_map.nil?
      self.errors.add(:response_map, ' Not found response map')
    else
      items = get_items(self)
      self.scores = get_answers(self, items)
      self
    end
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
        team_reviewing_enabled: response_map.team_reviewing_enabled
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
            question_type: score.question.question_type,
            seq: score.question.seq,
            questionnaire_id: score.question.questionnaire_id
          }
        }
      end
    }.to_json
  end
end
