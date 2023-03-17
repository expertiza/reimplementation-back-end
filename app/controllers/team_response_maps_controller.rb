class TeamResponseMapsController < ApplicationController
  before_action :set_team_response_map, only: %i[ show update destroy ]

  # GET /team_response_maps
  def index
    @team_response_maps = TeamResponseMap.all

    render json: @team_response_maps
  end

  # GET /team_response_maps/1
  def show
    render json: @team_response_map
  end

  # POST /team_response_maps
  def create
    @team_response_map = TeamResponseMap.new(team_response_map_params)

    if @team_response_map.save
      render json: @team_response_map, status: :created, location: @team_response_map
    else
      render json: @team_response_map.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /team_response_maps/1
  def update
    if @team_response_map.update(team_response_map_params)
      render json: @team_response_map
    else
      render json: @team_response_map.errors, status: :unprocessable_entity
    end
  end

  # DELETE /team_response_maps/1
  def destroy
    @team_response_map.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team_response_map
      @team_response_map = TeamResponseMap.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def team_response_map_params
      params.require(:team_response_map).permit(:team_reviewing_enabled)
    end
end
