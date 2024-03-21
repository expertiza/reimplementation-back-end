require 'response_helper'
class Api::V1::ResponsesController < ApplicationController
  include ResponseHelper

  # GET /responses
  def index
    responses = Response.all
    render json: responses, status: :ok
  end

  # GET /responses/1
  def show
    response = Response.find(params[:id])
    response = response.set_content(params, 'show')
    render json: response.serialize_response, status: :ok
  end

  # GET /responses/new
  def new
    response = Response.new
    response.map_id = params[:map_id]
    response.set_content(params, 'new')
    if response.errors.full_messages.length > 0
      error_message = ''
      response.errors.each { |e| error_message += e + "\n" }
      render json: { error: error_message }, status: :ok
    else

      render json: response.serialize_response, status: :ok
    end
  end

  # POST /responses
  def create
    is_submitted = params[:response][:is_submitted]
    response = Response.new

    response.validate(params, 'create')

    # only notify if is_submitted changes from false to true
    if response.errors.full_messages.length == 0
      response.save
      create_update_answers(response, params[:scores]) if params[:scores]

      if is_submitted
        questions = get_questions(response)
        response.scores = get_answers(response, questions)
        notify_instructor_on_difference(response)
        notify_peer_review_ready(response.response_map.id)
      end
      render json: { message: "Your response id #{response.id} was successfully saved." }, status: :created
    else
      error_msg = response.errors.full_messages.join('\n')
      render json: error_msg, status: :ok
    end
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # GET /responses/1/edit
  # Determining the current phase and check if a review is already existing for this stage.
  # If so, edit that version otherwise create a new version.

  # Prepare the parameters when student clicks "Edit"
  # response questions with answers and scores are rendered in the edit page based on the version number
  # redirect_to action: 'redirect', id: @map.map_id, return: 'locked', error_msg:
  def edit
    response = Response.find(params[:id])
    response.set_content(params, 'edit')
    if response.response_map.team_reviewing_enabled
      response = Lock.get_lock(response, current_user, Lock::DEFAULT_TIMEOUT)
      if response.nil?
        error_message = response_lock_action(response.map_id, true)
        render json: error_message, status: :ok
      end
    end

    if response.errors.full_messages.length > 0
      error_message = ''
      response.errors.each { |e| error_message += e + "\n" }
      render json: { error: error_message }, status: :ok
    else
      questions = get_questions(response)
      response.scores = get_answers(response, questions)
      render json: response.serialize_response, status: :ok
    end
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # PATCH/PUT /responses/1 
  # Update the response and answers when student "edit" existing response
  def update
    response = Response.find(params[:id])
    was_submitted = response.is_submitted

    # the response to be updated
    # Locking functionality added for E1973, team-based reviewing
    if response.response_map.team_reviewing_enabled && !Lock.lock_between?(response, current_user)
      error_message = response_lock_action(response.map_id, true)
      render json: error_message, status: :ok
    end

    response.validate(params, 'update')

    # only notify if is_submitted changes from false to true
    if response.errors.full_messages.length == 0
      response.save
      create_update_answers(response, params[:scores]) if params[:scores].present?
      notify_instructor_on_difference(response) if response.is_submitted == true && was_submitted == false
      render json: 'Your response was successfully saved.', status: :ok
    else
      error_msg = response.errors.full_messages.join('\n')
      render json: error_msg, status: :ok
    end
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end
  
  def destroy
    response = Response.find(params[:id])
    if delete_response?(response)
      render json: 'Your response was successfully deleted.', status: :ok
    end
  end
end
