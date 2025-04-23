# app/controllers/api/v1/response_maps_controller.rb
# Handles CRUD operations and special actions for ResponseMaps
# ResponseMaps represent the relationship between a reviewer and reviewee
class Api::V1::ResponseMapsController < ApplicationController
  before_action :set_response_map, only: [:show, :update, :destroy, :submit_response]

  # Lists all response maps in the system
  # GET /api/v1/response_maps
  def index
    @response_maps = ResponseMap.all
    render json: @response_maps
  end

  # Retrieves a specific response map by ID
  # GET /api/v1/response_maps/:id
  def show
    render json: @response_map
  end

  # Creates a new response map with the provided parameters
  # POST /api/v1/response_maps
  def create
    @response_map = ResponseMap.new(response_map_params)
    persist_and_respond(@response_map, :created)
  end

  # Updates an existing response map with new attributes
  # PATCH/PUT /api/v1/response_maps/:id
  def update
    @response_map.assign_attributes(response_map_params)
    persist_and_respond(@response_map, :ok)
  end

  # Removes a response map from the system
  # DELETE /api/v1/response_maps/:id
  def destroy
    @response_map.destroy
    head :no_content
  end

  # Handles the submission of a response associated with a response map
  # This also triggers email notifications if configured
  # POST /api/v1/response_maps/:id/submit_response
  def submit_response
    @response = @response_map.responses.find_or_initialize_by(id: params[:response_id])
    @response.assign_attributes(response_params)
    @response.is_submitted = true

    if @response.save
      # send feedback email now that it’s marked submitted
      FeedbackEmailService.new(@response_map, @response_map.assignment).call
      render json: { message: 'Response submitted successfully, email sent' }, status: :ok
      handle_submission(@response_map)
    else
      render json: { errors: @response.errors }, status: :unprocessable_entity
    end
  end

  # Processes the actual submission and handles email notifications
  # @param map [ResponseMap] The response map being submitted
  def handle_submission(map)
    FeedbackEmailService.new(map, map.assignment).call
    render json: { message: 'Response submitted successfully, email sent' }, status: :ok
    rescue StandardError => e
    Rails.logger.error "FeedbackEmail failed: #{e.message}"
    render json: { message: 'Response submitted, but email failed' }, status: :ok
    end

  # Generates a report of responses for a specific assignment
  # Can be filtered by type and grouped by rounds if applicable
  # GET /api/v1/response_maps/response_report/:assignment_id
  def response_report
    assignment_id = params[:assignment_id]
    report = ResponseMap.response_report(assignment_id, params[:type])
    render json: report
  end

  private

  # Locates the response map by ID and sets it as an instance variable
  # Renders a 404 error if the map is not found
  def set_response_map
    @response_map = ResponseMap.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Response map not found' }, status: :not_found
  end

  # Defines permitted parameters for response map creation/update
  # @return [ActionController::Parameters] Whitelisted parameters
  def response_map_params
    params.require(:response_map).permit(:reviewee_id, :reviewer_id, :reviewed_object_id)
  end

  # Defines permitted parameters for response submission
  # Includes nested attributes for scores
  # @return [ActionController::Parameters] Whitelisted parameters
  def response_params
    params.require(:response).permit(
      :additional_comment,
      :round,
      :is_submitted,
      scores_attributes: [:answer, :comments, :question_id]
    )
  end

  # Common method to persist records and generate appropriate responses
  # Handles submission processing if the record is marked as submitted
  # @param record [ActiveRecord::Base] The record to save
  # @param success_status [Symbol] HTTP status code for successful save
  def persist_and_respond(record, success_status)
    if record.save
      handle_submission(record) if record.is_submitted?
      render json: record, status: success_status
    else
      render json: record.errors, status: :unprocessable_entity
    end
  end
end