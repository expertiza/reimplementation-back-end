require 'response_dto'
require 'response_dto_handler'
require 'response_service'
class Api::V1::ResponsesController < ApplicationController
  
  
  def index
    @responses = Response.all
    render json: @responses, status: :ok
  end
  def show
    response = set_content(Action.SHOW, params)
    
    render json: response
  end
  def new
    response_dto = ResponseDto.new
    response_handler = ResponseDtoHandler.new
    response_handler.set_content(true, "new", response_dto, params)
    render json: response_dto
  end

  def create
    response = Response.new
    res_service = ResponseService.new
    response_handler = ResponseDtoHandler.new
    result = response_handler.accept_content(response, params, "create")
    msg = 'Your response was successfully saved.'
    error_msg = ''
    
    # only notify if is_submitted changes from false to true
    if (result[:response].response_map.is_a? ReviewResponseMap) && (!result[:was_submitted] && result[:response].is_submitted) && res_service.significant_difference?(result[:response])
      res_service.notify_instructor_on_difference(result[:response])
      res_service.email(result[:response].response_map.map_id)
    end
    # question1
    redirect_to controller: 'response', action: 'save', id: result[:response].response_map.map_id,
                return: params.permit(:return)[:return], msg: msg, error_msg: error_msg, review: params.permit(:review)[:review], save_options: params.permit(:save_options)[:save_options]
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
    response_dto =  ResponseDto.new
    response_handler = ResponseDtoHandler.new
    response_handler.set_content(false, "edit", response_dto, params)
    if response_dto.map.team_reviewing_enabled
      response = Lock.get_lock(response_dto.response, current_user, Lock::DEFAULT_TIMEOUT)
      if response.nil?
        # Replaced response_lock_action with below
        response_dto.locked = true
        return
      end
    end

    response_dto.modified_object = response.response_id
    response_dto.review_scores = []
    response_dto.review_questions.each do |question|
      response_dto.review_scores << Answer.where(response_id: response.response_id, question_id: question.id).first
    end
    render json: response_dto
  end
  # Update the response and answers when student "edit" existing response
  def update
    render nothing: true unless action_allowed?
    msg = ''
    begin
      res_service = ResponseService.new
      response_handler = ResponseDtoHandler.new
      response = Response.find(params[:id])
      # the response to be updated
      # Locking functionality added for E1973, team-based reviewing
      if response.response_map.team_reviewing_enabled && !Lock.lock_between?(response, current_user)
        # response_lock_action
        locked = true
        return
      end
      
      result = response_handler.accept_content(response, params, "update")
      
      if (result[:response].response_map.is_a? ReviewResponseMap) && result[:response].is_submitted && res_service.significant_difference?(result[:response])
        res_service.notify_instructor_on_difference(result[:response])
      end
      
    rescue StandardError
      msg = "Your response was not saved. Cause:189 #{$ERROR_INFO}"
    end
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Your response was submitted: #{result[:response].is_submitted}", request)
    render json :result
  end

  private
  # E2218: Method to initialize response and response map for update, delete and view methods
  def set_response
    @response = Response.find(params[:id])
    @map = @response.map
  end
end