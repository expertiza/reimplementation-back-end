# frozen_string_literal: true

class Response < ApplicationRecord
  include ScorableHelper
  include MetricHelper

  belongs_to :response_map, class_name: 'ResponseMap', foreign_key: 'map_id', inverse_of: false
  has_many :scores, class_name: 'Answer', foreign_key: 'response_id', dependent: :destroy, inverse_of: false
  
  alias map response_map
  delegate :questionnaire, :reviewee, :reviewer, to: :map
  
  
  # new_response if a flag parameter indicating that if user is requesting a new rubric to fill
  # if true: we figure out which questionnaire to use based on current time and records in assignment_questionnaires table
  # e.g. student click "Begin" or "Update" to start filling out a rubric for others' work
  # if false: we figure out which questionnaire to display base on @response object
  # e.g. student click "Edit" or "View"
  def set_content(new_response = false, action)
    assign_action_parameters
    @title = @map.get_title
    if @map.survey?
      @survey_parent = @map.survey_parent
    else
      @assignment = @map.assignment
    end
    @participant = @map.reviewer
    @contributor = @map.contributor
    new_response ? questionnaire_from_response_map : questionnaire_from_response
    set_dropdown_or_scale
    @review_questions = sort_questions(@questionnaire.questions)
    @min = @questionnaire.min_question_score
    @max = @questionnaire.max_question_score
    # The new response is created here so that the controller has access to it in the new method
    # This response object is populated later in the new method
    if new_response
      #Sometimes the response is already created and the new controller is called again (page refresh)
      @response = Response.where(map_id: @map.id, round: @current_round.to_i).order(updated_at: :desc).first
      if @response.nil?
        @response = Response.create(map_id: @map.id, additional_comment: '', round: @current_round.to_i, is_submitted: 0)
      end
    end
  end
  # This method is called within the Edit or New actions
  # It will create references to the objects that the controller will need when a user creates a new response or edits an existing one.
  def assign_action_parameters
    case params[:action]
    when 'edit'
      @header = 'Edit'
      @next_action = 'update'
      @response = Response.find(params[:id])
      @map = @response.map
      @contributor = @map.contributor
    when 'new'
      @header = 'New'
      @next_action = 'create'
      @feedback = params[:feedback]
      @map = ResponseMap.find(params[:id])
      @modified_object = @map.id
    end
    @return = params[:return]
  end
  
end
