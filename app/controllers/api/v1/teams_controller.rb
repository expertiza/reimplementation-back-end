class Api::V1::TeamsController < ApplicationController
  before_action :set_team, only: %i[show update destroy add_ta view_tas remove_ta copy ]
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  # GET /teams
  # List all the teams
  def index
    teams = Team.order(:id)
    render json: teams, status: :ok
    # teams = Team.order(:id)
    # team_data = {}
    #   teams.each do |team|
    #     team_data[team.name] = User.where(team_id: team.id)
    #   end
    # render json: team_data, status: :ok
  end

  # GET /teams/1
  # Get a team
  def show
    render json: @team, status: :ok
  end

  # POST /teams
  # Create a team
  def create
    team = Team.new(team_params)
    if team.save
      render json: team, status: :created
    else
      render json: team.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /teams/1
  # Update a team
  def update
    if @team.update(team_params)
      render json: @team, status: :ok
    else
      render json: @team.errors, status: :unprocessable_entity
    end
  end

  # DELETE /teams/1
  # Delete a team
  def destroy
    @team.destroy
    render json: { message: "Team with id #{params[:id]}, deleted" }, status: :no_content
  end

  def set_team
    @team = Team.find(params[:id])
    puts(@team.name)
  end

  def team_params
    params.require(:team).permit(:name)
  end

  def parameter_missing
    render json: { error: 'Parameter missing' }, status: :unprocessable_entity
  end
end

