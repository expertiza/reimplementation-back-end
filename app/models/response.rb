# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper
  include ResponseHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false

  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map

  def create_response_map
    response_map = ResponseMap.new
    response_map.reviewed_object_id = 1
    response_map.reviewer_id = 1
    response_map.reviewee_id = 2
    response_map.type = 'ReviewResponseMap'
    response_map.save
    return response_map.id
  end

  # Validates parameters for creating or updating a response. The method checks for the presence and validity
  # of the response map and specific fields based on the action (create or update). It ensures that
  # new responses do not duplicate existing ones and that updates are not made to already submitted responses.
  def validate_params(params, action)
    assign_map_id(params, action)
    return unless set_and_validate_response_map

    set_response_attributes(params)
    return if action_specific_validation(params, action)

    validate_submission_status(params) if action == 'update'
  end

  private

  # Assign map_id based on the action
  def assign_map_id(params, action)
    self.map_id = action == 'create' ? (params[:map_id] || params.dig(:response, :map_id)) : self.map_id
  end

  # Set and validate the existence of the response map
  def set_and_validate_response_map
    self.response_map = ResponseMap.includes(:responses).find_by(id: self.map_id)
    unless response_map
      errors.add(:response_map, 'not found')
      return false
    end
    true
  end

  # Set response attributes from params
  def set_response_attributes(params)
    self.round = params.dig(:response, :round)
    self.version_num = params.dig(:response, :version_num)
    self.additional_comment = params.dig(:response, :additional_comment)
    self.visibility = params.dig(:response, :visibility)
  end

  # Validate parameters specific to create or update actions
  def action_specific_validation(params, action)
    case action
    when 'create'
      validate_create_conditions
    when 'update'
      validate_update_conditions(params)
    end
  end

  # Validate conditions specific to the create action
  def validate_create_conditions
    existing_response = response_map.responses.find_by(map_id: self.map_id, round: self.round, version_num: self.version_num)
    if existing_response
      errors.add('response', "Already existed the response round #{existing_response.round} and version_num #{existing_response.version_num}. Please update the version or round.")
      return true
    end
    false
  end

  # Validate conditions specific to the update action
  def validate_update_conditions(params)
    if self.is_submitted
      errors.add('response', "Response id #{self.id} is already submitted and cannot be updated.")
      return true
    elsif params.dig(:response, :map_id) && params[:response][:map_id] != self.map_id
      errors.add('response', "Response id #{self.id} cannot change its map_id.")
      return true
    end
    false
  end

  # Validate the submission status of the response
  def validate_submission_status(params)
    self.is_submitted = params.dig(:response, :is_submitted)
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