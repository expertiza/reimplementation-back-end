class Api::V1::JoinTeamRequestsController < ApplicationController
  before_action :set_join_team_request, only: %i[ show update destroy ]

  # GET /join_team_requests
  def index
    @join_team_requests = JoinTeamRequest.all

    render json: @join_team_requests
  end

  # GET /join_team_requests/1
  def show
    render json: @join_team_request
  end

  # POST /join_team_requests
  def create
    @join_team_request = JoinTeamRequest.new(join_team_request_params)

    if @join_team_request.save
      render json: @join_team_request, status: :created, location: @join_team_request
    else
      render json: @join_team_request.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /join_team_requests/1
  def update
    if @join_team_request.update(join_team_request_params)
      render json: @join_team_request
    else
      render json: @join_team_request.errors, status: :unprocessable_entity
    end
  end

  # DELETE /join_team_requests/1
  def destroy
    @join_team_request.destroy
  end
  
  private
  
  # Use callbacks to share common setup or constraints between actions.
  def set_join_team_request
    @join_team_request = JoinTeamRequest.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def join_team_request_params
    params.fetch(:join_team_request, {})
  end
end
