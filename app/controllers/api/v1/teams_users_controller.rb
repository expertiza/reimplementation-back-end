class Api::V1::TeamsUsersController < ApplicationController
  before_action :find_teams_user, only: [:update, :delete]

  rescue_from ActiveRecord::RecordNotFound, with: :teams_user_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  # GET /teams_users
  # List all the teams_users
  def index
    teams_users = TeamsUser.all
    render json: teams_users, status: :ok
  end

  # GET /teams/1
  # Get the users of a particular team
  def show
    team = Team.find(params[:id])
    teams_users = TeamsUser.where(team_id: params[:id])
    render json: teams_users, status: :ok
  end

  # GET /teams/1/teams_users/new
  # Render form to create a new teams_user for a specific team
  def new
    @team = Team.find(params[:id])
    render json: team, status: :ok
  end

  # POST /teams_users
  # Create a new teams_user
  def create
    teams_user = TeamsUser.new(teams_user_params)
    if teams_user.save
      render json: teams_user, status: :created
    else
      render json: { error: teams_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /teams_users/1
  # Update an existing teams_user
  def update
    if @teams_user.update(teams_user_params)
      render json: @teams_user, status: :ok
    else
      render json: { error: @teams_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /teams_users/1
  # Remove a teams_user
  def delete
    parent_id = Team.find(@teams_user.team_id).parent_id
    @user = User.find(@teams_user.user_id)

    if @teams_user.destroy
      flash_message = "The team user \"#{@user.name}\" has been successfully removed."
    else
      flash_message = "Failed to remove the team user."
    end

    respond_to do |format|
      format.html { redirect_to_teams_list(parent_id, flash_message) }
      format.json { render json: { message: flash_message }, status: (@teams_user.destroyed? ? :no_content : :unprocessable_entity) }
    end
  end

  private

  def find_teams_user
    @teams_user = TeamsUser.find(params[:id])
  end

  def teams_user_params
    params.require(:teams_user).permit(:team_id, :user_id, :duty_id, :pair_programming_status, :participant_id)
  end

  def teams_user_not_found
    render json: { error: "TeamsUser with id #{params[:id]} not found" }, status: :not_found
  end

  def parameter_missing
    render json: { error: "Parameter missing" }, status: :unprocessable_entity
  end

  def redirect_to_teams_list(parent_id, flash_message)
    redirect_to controller: 'teams', action: 'list', id: parent_id, flash: { success: flash_message }
  end
end
