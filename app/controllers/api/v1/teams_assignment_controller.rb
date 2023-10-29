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
  end

  # POST /team_assignments
  # Create a team_assignment
  def create
  end

  # PATCH/PUT /team_assignments/1
  # Update a team_assignment
  def update
  end

  # DELETE /team_assignments/1
  # Delete a team_assignment
  def destroy
  end

  # Creates a copy of the team_assignment
  def copy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_team_assignment
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
  