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
      map_id = params[:map_id]
    else
      map_id = response_map.id
    end
    response_map = ResponseMap.includes(:responses).find(map_id)
    if response_map.nil?
      self.errors.push("Not found response map")
      return
    end

    response_map = response_map
    round = round || params[:response][:round]
    additional_comment = params[:response][:comments] || additional_comment
    version_num = params[:response][:version_num] || version_num

    if action == 'create'
      existing_response = response_map.responses.where("round = ? and version_num = ?", round, version_num)
      if existing_response.present?
        self.errors.push("Already existed.")
        return
      end
    elsif action == 'update'
      if params[:response][:is_submitted].present?
        if is_submitted
          self.errors.push("Already submitted.")
          return
        end
      end
    end
    is_submitted = params[:response][:is_submitted] || is_submitted
  end

  def set_content(params, action)
    response_map = ResponseMap.find(map_id)
    if response_map.nil?
      self.errors.push(' Not found response map')
    else
      self
    end
    questions = get_questions(self)
    scores = get_answers(self, questions)
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
            txt: score.question.txt
          }
        }
      end
    }.to_json
  end

end





