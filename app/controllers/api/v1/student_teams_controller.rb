class Api::V1::StudentTeamsController < ApplicationController
  include StudentTeamsHelper
  # include AuthorizationHelper
  # autocomplete :user, :name
  
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  before_action :set_team, only: %i[update destroy]
  before_action :set_student, only: %i[view create remove_participant]
  before_action :set_all_teams, only: %i[index]

  # GET /api/v1/student_teams
  # Retrieve all student teams information
  def index
      # check for mentored teams as well
    render json: @all_teams, status: :ok
  end

  # GET /student_teams/:id
  # Show details of a specific student team
  def show
    render json: current_team, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # POST /student_teams
  # Create a new team for the student
  def create
    team_name = params[:team][:name].presence || generate_team_name
    existing_teams = AssignmentTeam.where(name: team_name, assignment_id: @student.assignment_id)

    if existing_teams.empty?
      parent = Assignment.find_by(id: @student.assignment_id)
      team = if parent&.auto_assign_mentor
               MentoredTeam.new(name: team_name, assignment_id: @student.assignment_id)
             else
               AssignmentTeam.new(name: team_name, assignment_id: @student.assignment_id)
             end

      if team.save
        user = User.find(@student.user_id)
        team.add_member(user, team.assignment_id)
        render json: team, status: :created
      else
        render json: team.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'That team name is already in use.' }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /student_teams
  # Update team details
  def update
    team_name = params[:team][:name]
    if team_name.blank?
      return render json: { error: 'Team name should not be empty.' }, status: :unprocessable_entity
    end

    matching_teams = AssignmentTeam.where(name: team_name, assignment_id: @team.assignment.id)
    if matching_teams.empty?
      if @team.update(name: team_name)
        render json: { message: "The team: '#{@team.name}' has been updated successfully." }, status: :ok
      else
        render json: { error: @team.errors.full_messages }, status: :unprocessable_entity
      end
    elsif matching_teams.length == 1 && matching_teams.first.name == @team.name
      render json: { message: "The team: '#{@team.name}' has been updated successfully." }, status: :ok
    else
      render json: { error: 'That team name is already in use.' }, status: :unprocessable_entity
    end
  end

  # DELETE /student_teams/:id
  # Delete a specific team
  def destroy
    if current_team.destroy
      head :no_content
    else
      render json: { error: 'Failed to delete team.' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "AssignmentTeam with id #{params[:id]} not found." }, status: :not_found
  end

  # DELETE /student_teams/:id/remove_participant
  def remove_participant
    begin
      team = AssignmentTeam.find(params[:id])
      destroyed, message = team.remove_team_user(user_id: @student.user_id)
      Invitation.where(from_user: @student, assignment: @student.assignment_id).destroy_all
      render json: { message: message }, status: destroyed ? :no_content : :not_found
        
  rescue ActiveRecord::RecordNotFound => e
      render json: { message: 'Team not found.' }, status: :not_found
    end
  end
end
