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
    if @response_map.save
      render json: @response_map, status: :created
    else
      render json: @response_map.errors, status: :unprocessable_entity
    end
  end

  # Updates an existing response map with new attributes
  # PATCH/PUT /response_maps/:id
  def update
    @response_map.assign_attributes(response_map_params)
    if @response_map.save
      render json: @response_map, status: :ok
    else
      render json: @response_map.errors, status: :unprocessable_entity
    end
  end

  # Removes a response map from the system
  # DELETE /response_maps/:id
  def destroy
    @response_map.destroy
    head :no_content
  end

  # Retrieves all response maps for a specific assignment
  # GET /response_maps/assignment/:assignment_id
  def fetch_response_maps_for_assignment
    @response_maps = ResponseMap.for_assignment(params[:assignment_id])
    render json: @response_maps
  end

  # Gets all response maps for a specific reviewer (includes responses)
  # GET /response_maps/reviewer/:reviewer_id
  def fetch_response_maps_for_reviewer
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
end
