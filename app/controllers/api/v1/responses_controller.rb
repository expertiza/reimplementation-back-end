require 'response_dto'
require 'response_dto_handler'
require 'response_helper'
class Api::V1::ResponsesController < ApplicationController
  
  
  def index
    @responses = Response.all
    render json: @responses, status: :ok
  end
  def show
    response = Response.find(params[:id])
    response_handler = ResponseDtoHandler.new(response)
    response_dto = response_handler.set_content(false, "show", params)
    
    render json: response_dto
  end
  def new
    errors = []
    res_helper = ResponseHelper.new
    response = Response.new
    response_handler = ResponseDtoHandler.new(response)
    response_dto = response_handler.set_content(true, "new", params)
    if response_dto.errors.length > 0
      error_message = ""
      response_dto.each {|e| error_message += e + "\n"}
      render json: {error: error_message}, status: :ok
    else
      res_helper.init_answers(response_dto)
      response_dto.answers = res_helper.get_answers_for_response(response_dto.response.id)
      #render json: response_dto.as_json(include: {response: {include: :response_map}}), status: :ok
      render json: response_dto.as_json, status: :ok
    end
    
  end

  def create
    response = Response.new
    res_helper = ResponseHelper.new
    response_handler = ResponseDtoHandler.new(response)
    result = response_handler.accept_content(params, "create")
    msg = 'Your response was successfully saved.'
    error_msg = ''
    
    # only notify if is_submitted changes from false to true
    if (result[:response].response_map.is_a? ReviewResponseMap) && (!result[:was_submitted] && result[:response].is_submitted) && res_helper.significant_difference?(result[:response])
      res_helper.notify_instructor_on_difference(result[:response])
      res_helper.email(result[:response].response_map.map_id)
    end
    render json: result
    
  end

  

  # Determining the current phase and check if a review is already existing for this stage.
  # If so, edit that version otherwise create a new version.

  # Prepare the parameters when student clicks "Edit"
  # response questions with answers and scores are rendered in the edit page based on the version number
  def edit
    # @prev = Response.where(map_id: @map.id)
    # @review_scores = @prev.to_a
    # if @prev.present?
    #   @sorted = @review_scores.sort do |m1, m2|
    #     if m1.version_num.to_i && m2.version_num.to_i
    #       m2.version_num.to_i <=> m1.version_num.to_i
    #     else
    #       m1.version_num ? -1 : 1
    #     end
    #   end
    #   @largest_version_num = @sorted[0]
    # end
    # Added for E1973, team-based reviewing
    response = Response.find(params[:id])
    response_handler = ResponseDtoHandler.new(response)
    response_dto = response_handler.set_content(false, "edit", params)
    if response_dto.response.response_map.team_reviewing_enabled
      response = Lock.get_lock(response_dto.response, current_user, Lock::DEFAULT_TIMEOUT)
      if response.nil?
        # Replaced response_lock_action with below
        response_dto.locked = true
        return
      end
    end

    response_dto.modified_object = response.response_map.id
    response_dto.review_scores = []
    response_dto.review_questions.each do |question|
      response_dto.review_scores << Answer.where(response_id: response.id, question_id: question.id).first
    end
    render json: response_dto
  end
  # Update the response and answers when student "edit" existing response
  def update
    # render nothing: true unless action_allowed?
    # msg = ''
    begin
      res_helper = ResponseHelper.new
      response = Response.find(params[:id])
      response_handler = ResponseDtoHandler.new(response)

      # the response to be updated
      # Locking functionality added for E1973, team-based reviewing
      if response.response_map.team_reviewing_enabled && !Lock.lock_between?(response, current_user)
        # response_lock_action
        locked = true
        return
      end
      
      result = response_handler.accept_content(params, "update")
      
      if (result[:response].response_map.is_a? ReviewResponseMap) && result[:response].is_submitted && res_helper.significant_difference?(result[:response])
        res_helper.notify_instructor_on_difference(result[:response])
      end
      
    rescue StandardError
      msg = "Your response was not saved. Cause:189 #{$ERROR_INFO}"
    end
    render json: result
  end

  def new_feedback
    review = Response.find(params[:id]) unless params[:id].nil?
    if review
      reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: review.map.assignment.id).first
      map = FeedbackResponseMap.where(reviewed_object_id: review.id, reviewer_id: reviewer.id).first
      if map.nil?
        # if no feedback exists by dat user den only create for dat particular response/review
        map = FeedbackResponseMap.create(reviewed_object_id: review.id, reviewer_id: reviewer.id, reviewee_id: review.map.reviewer.id)
      end
      redirect_to action: 'new', id: map.id, return: 'feedback'
    else
      redirect_back fallback_location: root_path
    end
  end
  private
  # E2218: Method to initialize response and response map for update, delete and view methods
  def set_response
    @response = Response.find(params[:id])
    @map = @response.map
  end
end