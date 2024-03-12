require 'response_helper'
class Api::V1::ResponsesController < ApplicationController
  
  
  def index
    @responses = Response.all
    render json: @responses, status: :ok
  end
  def show
    @response = Response.find(params[:id])
    @response.set_content(params, "show")
    render json: @response
  end

  def new
    res_helper = ResponseHelper.new
    @response = Response.new
    @response.map_id = params[:map_id]
    @response.set_content(params, 'new')
    if @response.errors.length > 0
      error_message = ""
      @response.errors.each {|e| error_message += e + "\n"}
      render json: {error: error_message}, status: :ok
    else
      questions = res_helper.get_questions(@response)
      @response.scores = res_helper.init_answers(@response, questions)
      render json: @response, status: :ok
    end
  end

  def create
    begin
      is_submitted = params[:response][:is_submitted]
      @response = Response.new
      res_helper = ResponseHelper.new
      @response.accept_content(params, "create")

      # only notify if is_submitted changes from false to true
      if @response.error.length == 0
        @response.save
        @res_helper.create_answers(@response.id, params[:answers]) if params[:answers]
        if is_submitted
          res_helper.notify_instructor_on_difference(@response)
          res_helper.email(@response.response_map.map_id)
          render json: 'Your response was successfully saved.', status: :ok
        else
          error_msg = @response.errors.join('\n')
          render json: error_msg, status: :ok
        end
      end
    rescue StandardError
      render json: "Your response was not saved.", status: :unprocessable_entity
    end
  end

  # Determining the current phase and check if a review is already existing for this stage.
  # If so, edit that version otherwise create a new version.

  # Prepare the parameters when student clicks "Edit"
  # response questions with answers and scores are rendered in the edit page based on the version number
  def edit
    @response = Response.find(params[:id])
    res_helper = ResponseHelper.new
    @response.set_content(params, 'edit')
    if @response.response_map.team_reviewing_enabled
      @response = Lock.get_lock(@response, current_user, Lock::DEFAULT_TIMEOUT)
      if @response.nil?
        # todo Replaced response_lock_action with below
        # Need to know more details of the response_lock_action
        #response.locked = true
        return
      end
    end

    if @response.errors.length > 0
      error_message = ""
      @response.errors.each {|e| error_message += e + "\n"}
      render json: {error: error_message}, status: :ok
    else
      questions = res_helper.get_questions(@response)
      @response.scores = res_helper.init_answers(@response, questions)
      render json: @response, status: :ok
    end
  end



  # Update the response and answers when student "edit" existing response
  def update
    begin
      res_helper = ResponseHelper.new
      @response = Response.find(params[:id])
      was_submitted = @response.is_submitted

      # the response to be updated
      # Locking functionality added for E1973, team-based reviewing
      if @response.response_map.team_reviewing_enabled && !Lock.lock_between?(@response, current_user)
        # response_lock_action
        locked = true
        return
      end
      
      @response.accept_content(params, "update")

      # only notify if is_submitted changes from false to true
      if @response.error.length == 0
        @response.save
        res_helper.create_answers(@response.id, params[:answers]) if params[:answers].present?
        if is_submitted == true && was_submitted == false
          res_helper.notify_instructor_on_difference(@response)
          render json: 'Your response was successfully saved.', status: :ok
        else
          error_msg = @response.errors.join('\n')
          render json: error_msg, status: :ok
        end
      end
      
    rescue StandardError
      render json: "Your response was not saved. Cause:189 #{$ERROR_INFO}", status: :unprocessable_entity
    end
  end

  private


end