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
    response = response_handler.set_content(params, "show")
    
    render json: response
  end

  def create
    begin
      is_submitted = params[:response][:is_submitted]
      response = Response.new
      res_helper = ResponseHelper.new
      response_handler = ResponseDtoHandler.new(response)
      response_handler.accept_content(params, "create")

      # only notify if is_submitted changes from false to true
      if response_handler.error.length == 0
        if is_submitted
          res_helper.notify_instructor_on_difference(response_handler.response)
          res_helper.email(response_handler.response.response_map.map_id)
          render json: 'Your response was successfully saved.', status: :ok
        else
          error_msg = response_handler.errors.join('\n')
          render json: error_msg, status: :ok
        end
      end
    rescue StandardError
      render json: "Your response was not saved. Cause:189 #{$ERROR_INFO}", status: :unprocessable_entity
    end
  end

  # Update the response and answers when student "edit" existing response
  def update
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
      
      response_handler.accept_content(params, "update")

      # only notify if is_submitted changes from false to true
      if response_handler.error.length == 0
        if is_submitted
          res_helper.notify_instructor_on_difference(response_handler.response)
          render json: 'Your response was successfully saved.', status: :ok
        else
          error_msg = response_handler.errors.join('\n')
          render json: error_msg, status: :ok
        end
      end
      
    rescue StandardError
      render json: "Your response was not saved. Cause:189 #{$ERROR_INFO}", status: :unprocessable_entity
    end
  end

  private


end