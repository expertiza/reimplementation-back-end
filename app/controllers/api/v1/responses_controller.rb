require 'response_helper'
class Api::V1::ResponsesController < ApplicationController
  include ResponseHelper

  # GET /responses
  # Returns a list of all responses.
  def index
    responses = Response.all
    render json: responses, status: :ok
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # GET /responses/1
  # # Retrieves and renders a single response based on its ID.
  # The response's content is prepared before rendering.
  def show
    begin
      response = Response.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Not found" }, status: :not_found
      return
    end
    response = response.set_content
    render json: response.serialize_response, status: :ok
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # GET /responses/new
  # Initializes a new response object for creation.
  # Prepares the response's content and renders it; handles errors if any are present.
  def new
    response = Response.new
    response.map_id = params[:map_id]
    response.set_content
    if response.errors.full_messages.length > 0
      render json: response.errors, status: :unprocessable_entity
    else
      render json: response.serialize_response, status: :ok
    end
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # POST /responses
  # Creates a new response based on the submitted parameters.
  # Notifies the instructor if the response is newly submitted.
  # Handles parameter validation and saving of associated answers.
  def create
    is_submitted = params[:response][:is_submitted]
    response = Response.new
    response.validate_params(params, 'create')

    if response.errors.full_messages.length == 0
      response.save
      create_update_answers(response, params[:scores]) if params[:scores]

      if is_submitted
        items = get_items(response)
        response.scores = get_answers(response, items)
        notify_instructor_on_difference(response)
        notify_peer_review_ready(response.response_map.id)
      end
      render json: { message: "Your response id #{response.id} was successfully saved." }, status: :created
    else
      render json: response.errors, status: :unprocessable_entity
    end
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # GET /responses/1/edit
  # Prepares a response for editing by retrieving the current items and answers.
  # Includes locking functionality to prevent concurrent edits.
  def edit
    begin
      response = Response.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Not found" }, status: :not_found
      return
    end
    response.set_content
    if response.response_map.team_reviewing_enabled
      response = Lock.get_lock(response, current_user, Lock::DEFAULT_TIMEOUT)
      if response.nil?
        error_message = response_lock_action(response.map_id, true)
        render json: error_message, status: :unprocessable_entity
      end
    end
    if response.errors.full_messages.length > 0
      render json: response.errors, status: :unprocessable_entity
    else
      items = get_items(response)
      response.scores = get_answers(response, items)
      render json: response.serialize_response, status: :ok
    end
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # PATCH/PUT /responses/1
  # Updates an existing response with new data.
  # Validates parameters, saves changes, and notifies the instructor if the submission status changes.
  def update
    begin
      response = Response.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Not found" }, status: :not_found
      return
    end
    was_submitted = response.is_submitted
    if response.response_map.team_reviewing_enabled && !Lock.lock_between?(response, current_user)
      error_message = response_lock_action(response.map_id, true)
      render json: error_message, status: :ok
    end
    response.validate_params(params, 'update')
    if response.errors.full_messages.length == 0
      response.save
      create_update_answers(response, params[:scores]) if params[:scores].present?
      notify_instructor_on_difference(response) if response.is_submitted == true && was_submitted == false
      render json: 'Your response was successfully saved.', status: :ok
    else
      render json: response.errors, status: :unprocessable_entity
    end
  rescue StandardError
    render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end

  # DELETE /responses/1
  # Deletes a response after checking if it is eligible for deletion.
  def destroy
    response = Response.find(params[:id])
    if delete_answers?(response)
      response.destroy!
      render json: 'Your response was successfully deleted.', status: :ok
    else
      render json: 'Deletion conditions not met.', status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: "Request failed. #{e.message}", status: :unprocessable_entity
  end
end
