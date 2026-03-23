# app/controllers/response_maps_controller.rb
# Handles CRUD operations and special actions for ResponseMaps
# ResponseMaps represent the relationship between a reviewer and reviewee
class ResponseMapsController < ApplicationController
  before_action :set_response_map, only: [:show, :update, :destroy]

  # Retrieves a specific response map by ID
  # GET /response_maps/:id
  def show
    render json: @response_map
  end

  # Creates a new response map with the provided parameters
  # POST /response_maps
  def create
    @response_map = ResponseMap.new(response_map_params)
    persist_and_respond(@response_map, :created)
  end

  # Updates an existing response map with new attributes
  # PATCH/PUT /response_maps/:id
  def update
    @response_map.assign_attributes(response_map_params)
    persist_and_respond(@response_map, :ok)
  end

  # Removes a response map from the system
  # DELETE /response_maps/:id
  def destroy
    @response_map.destroy
    head :no_content
  end

  # Generates a report of responses for a specific assignment
  # Can be filtered by type and grouped by rounds if applicable
  # GET /response_maps/response_report/:assignment_id
  def response_report
    assignment_id = params[:assignment_id]
    report = ResponseMapReports::ReportDispatcher.new.call(assignment_id:, type: params[:type])
    render json: report
  end

  # Retrieves all response maps for a specific assignment
  # GET /response_maps/assignment/:assignment_id
  def fetch_response_maps_by_assignment
    @response_maps = ResponseMap.for_assignment(params[:assignment_id])
    render json: @response_maps
  end

  # Gets all response maps for a specific reviewer (includes responses)
  # GET /response_maps/reviewer/:reviewer_id
  def fetch_response_maps_by_reviewer
    @response_maps = ResponseMap.for_reviewer_with_responses(params[:reviewer_id])
    render json: @response_maps, include: :responses
  end

  # Computes completion metrics for response maps in an assignment:
  # - total_response_maps: all maps linked to the assignment
  # - completed_response_maps: maps with at least one submitted response
  # - response_rate: percentage of completed maps (0 if no maps exist)
  # GET /response_maps/response_rate/:assignment_id
  def response_rate
    stats = ResponseMap.response_rate_for_assignment(params[:assignment_id])
    render json: stats
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
      render json: record, status: success_status
    else
      render json: record.errors, status: :unprocessable_entity
    end
  end
end
