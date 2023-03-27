class ResponseMapsController < ApplicationController
  before_action :set_response_map, only: %i[ show update destroy ]

  # GET /response_maps
  def index
    @response_maps = ResponseMap.all

    render json: @response_maps
  end

  # GET /response_maps/1
  def show
    render json: @response_map
  end

  # POST /response_maps
  def create
    @response_map = ResponseMap.new(response_map_params)

    if @response_map.save
      render json: @response_map, status: :created, location: @response_map
    else
      render json: @response_map.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /response_maps/1
  def update
    if @response_map.update(response_map_params)
      render json: @response_map
    else
      render json: @response_map.errors, status: :unprocessable_entity
    end
  end

  # DELETE /response_maps/1
  def destroy
    @response_map.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_response_map
      @response_map = ResponseMap.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def response_map_params
      params.require(:response_map).permit(:reviewed_object_id, :reviewer_id, :reviewee_id, :type, :calibrate_to)
    end
end
