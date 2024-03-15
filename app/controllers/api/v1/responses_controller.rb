require 'response_helper'
class Api::V1::ResponsesController < ApplicationController
  
  def index
    @responses = Response.all
    render json: @responses, status: :ok
  end
  def show
    response = Response.find(params[:id])
    response_handler = ResponseHandler.new(response)
    response = response_handler.set_content(params, "show")

    render json: response, status: :ok
  end

  def new
    res_helper = ResponseHelper.new
    response = Response.new
    response.map_id = params[:map_id]
    response_handler = ResponseHandler.new(response)
    response_handler.set_content(params, 'new')
    if response_handler.errors.length > 0
      error_message = ""
      response_handler.errors.each {|e| error_message += e + "\n"}
      render json: {error: error_message}, status: :ok
    else
      
      render json: response, status: :ok
    end
  end

  def create
    begin
      is_submitted = params[:response][:is_submitted]
      response = Response.new
      res_helper = ResponseHelper.new
      response_handler = ResponseHandler.new(response)
      response_handler.validate(params, "create")

      # only notify if is_submitted changes from false to true
      if response_handler.errors.length == 0
        response.save
        res_helper.create_update_answers(response, params[:scores]) if params[:scores]
        
        if is_submitted
          questions = res_helper.get_questions(response)
          response.scores = res_helper.get_answers(response, questions)
          res_helper.notify_instructor_on_difference(response)
          res_helper.notify_peer_review_ready(response.response_map.id)
        end
        render json: 'Your response was successfully saved.', status: :created
      else
        error_msg = response_handler.errors.join('\n')
        render json: error_msg, status: :ok
      end
    rescue StandardError
      render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
    end
  end

  # Determining the current phase and check if a review is already existing for this stage.
  # If so, edit that version otherwise create a new version.

  # Prepare the parameters when student clicks "Edit"
  # response questions with answers and scores are rendered in the edit page based on the version number
  # redirect_to action: 'redirect', id: @map.map_id, return: 'locked', error_msg: 
  def edit
    begin
      response = Response.find(params[:id])
      response_handler = ResponseHandler.new(response)
      res_helper = ResponseHelper.new
      response_handler.set_content(params, 'edit')
      if response.response_map.team_reviewing_enabled
        response = Lock.get_lock(response, current_user, Lock::DEFAULT_TIMEOUT)
        if response.nil?
          error_message = res_helper.response_lock_action(response.map_id, true)
          render json: error_message, status: :ok
        end
      end

      if response_handler.errors.length > 0
        error_message = ""
        response_handler.errors.each {|e| error_message += e + "\n"}
        render json: {error: error_message}, status: :ok
      else
        questions = res_helper.get_questions(response)
        response.scores = res_helper.get_answers(response, questions)
        render json: response, status: :ok
      end
    rescue StandardError
      render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
    end
  end
  



  # Update the response and answers when student "edit" existing response
  def update
    begin
      res_helper = ResponseHelper.new
      response = Response.find(params[:id])
      was_submitted = response.is_submitted
      response_handler = ResponseHandler.new(response)

      # the response to be updated
      # Locking functionality added for E1973, team-based reviewing
      if response.response_map.team_reviewing_enabled && !Lock.lock_between?(response, current_user)
        error_message = res_helper.response_lock_action(response.map_id, true)
        render json: error_message, status: :ok
      end
      
      response_handler.validate(params, "update")

      # only notify if is_submitted changes from false to true
      if response_handler.errors.length == 0
        response.save
        res_helper.create_update_answers(response, params[:scores]) if params[:scores].present?
        if response.is_submitted == true && was_submitted == false
          res_helper.notify_instructor_on_difference(response)
        end
        render json: 'Your response was successfully saved.', status: :ok
      else
        error_msg = response_handler.errors.join('\n')
        render json: error_msg, status: :ok
      end
      
    rescue StandardError
      render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
    end
  end

  private
    
end