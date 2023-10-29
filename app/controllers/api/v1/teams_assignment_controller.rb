class Api::V1::TeamsAssignmentController < ApplicationController
    
  before_action :set_team_assignment, only: %i[ show update destroy add_ta view_tas remove_ta copy ]
  rescue_from ActiveRecord::RecordNotFound, with: :team_assignment_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  # GET /team_assignments
  # List all the team_assignments
  def index
    team_assignment = TeamAssignment.all
    render json: team_assignment, status: :ok
  end

  # GET /team_assignments/1
  # Get a team_assignment
  def show
    render json: @team_assignment, status: :ok
  end

  # POST /team_assignments
  # Create a team_assignment
  def create
    team_assignment = TeamAssignment.new(team_assignment_params)
    if team_assignment.save
      render json: team_assignment, status: :created
    else
      render json: team_assignment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /team_assignments/1
  # Update a team_assignment
  def update
    if @team_assignment.update(team_assignment_params)
      render json: @team_assignment, status: :ok
    else
      render json: @team_assignment.errors, status: :unprocessable_entity
    end
  end

  # DELETE /team_assignments/1
  # Delete a team_assignment
  def destroy
    @team_assignment.destroy
    render json: { message: "Team assignment with id #{params[:id]}, deleted" }, status: :no_content
  end

  # Creates a copy of the team_assignment
  def copy
    if @team_assignment.copy_team_assignment
      render json: { message: "The team assignment #{@team_assignment.name} has been successfully copied" }, status: :ok
    else
      render json: { message: "The team assignment was not able to be copied" }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_team_assignment
    @team_assignment = TeamAssignment.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def team_assignment_params
  end

  def team_assignment_not_found
  end

  def parameter_missing
    render json: { error: "Parameter missing" }, status: :unprocessable_entity
  end
end
  