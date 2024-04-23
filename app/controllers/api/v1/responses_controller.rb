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
    response.map_id = params[:response][:map_id]
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
    if response.response_map.team_reviewing_enabled && false   # !Lock.lock_between?(response, current_user)
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
      render json: "The response id #{params[:id]} was successfully deleted.", status: :ok
    else
      render json: 'Deletion conditions not met.', status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: "Request failed. #{e.message}", status: :unprocessable_entity
  end
  
  # POST /responses/show_calibration_results_for_student
  # Can't be a GET as we expect the following arguments to be passed in: calibration_response_map_id, review_response_map_id
  # Returns the response information for both map_ids.     
  def show_calibration_results_for_student	
	calibration_response_map_id = params[:calibration_response_map_id]
	review_response_map_id = params[:review_response_map_id]
	
	# Get the responses from the respective map_ids
	begin
      calibration_response = Response.find_by!(map_id: calibration_response_map_id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Calibration response not found" }, status: :not_found
      return
    end
	begin
      review_response = Response.find_by!(map_id: review_response_map_id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Review response not found" }, status: :not_found
      return
    end
	
	# Get the questions and answeres for each response
	calibration_items = get_items(calibration_response)
    calibration_response.scores = get_answers(calibration_response, calibration_items)
	
	review_items = get_items(review_response)
    review_response.scores = get_answers(review_response, review_items)
	
	# return the results as a formatted json object
	render json: {calibration_response: JSON.parse(calibration_response.serialize_response), review_response: JSON.parse(review_response.serialize_response)}, status: :ok
	
	rescue StandardError
      render json: "Request failed. #{$ERROR_INFO}", status: :unprocessable_entity
  end
  
end
