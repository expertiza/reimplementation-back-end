class Api::V1::StudentTeamsController < ApplicationController
  include StudentTeamsHelper
  
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  before_action :set_student, only: %i[view create remove_participant add_participant]

  # GET /api/v1/student_teams
  # Retrieve all student teams information
  def index
    fetch_all_teams_and_participants all_teams
  end

  # GET /student_teams/:id
  # Show details of a specific student team
  def show
    fetch_team_and_participants current_team
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
      team = AssignmentTeam.new(name: team_name, assignment_id: @student.assignment_id)
      if parent&.auto_assign_mentor
        team = team.upgrade_to_mentored_team
      end
      if team.save
        user = User.find(@student.user_id)
        team.add_member(user, team.assignment_id)
        fetch_team_and_participants team, :created
      else
        render json: team.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'That team name is already in use.' }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /student_teams
  # Update team details: name
  def update
    team = AssignmentTeam.find(params[:team_id])
    team_name = params[:team][:name]
    if team_name.blank?
      return render json: { error: 'Team name cannot be empty.' }, status: :unprocessable_entity
    end

    matching_teams = AssignmentTeam.where(name: team_name, assignment_id: team.assignment.id)
    success_response = -> { render json: { message: "The team: '#{team.name}' has been updated successfully." }, status: :ok }
    if matching_teams.empty?
      if team.update(name: team_name)
        success_response.call
      else
        render json: { error: team.errors.full_messages }, status: :unprocessable_entity
      end
    elsif matching_teams.length == 1 && matching_teams.first.name == team.name
      success_response.call
    else
      render json: { error: 'That team name is already in use.' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "AssignmentTeam with id #{params[:team_id]} not found." }, status: :not_found
  end

  # DELETE /student_teams/:id
  # Delete a specific team
  def destroy
    team = AssignmentTeam.find(params[:id])
    if team.destroy
      head :no_content
    else
      render json: { error: 'Failed to delete team.' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "AssignmentTeam with id #{params[:id]} not found." }, status: :not_found
  end

  # DELETE /student_teams/:id/remove_participant
  # Remove a participant from the team
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

  # PATCH /student_teams/:id/add_participant
  # Add a participant to the team
  def add_participant
    team = AssignmentTeam.find_by(id: params[:id])
    if team.nil?
      render json: { error: "Team with id #{params[:id]} not found" }, status: :not_found
    else
      user = User.find(@student.user_id)
      begin
        team.add_member(user, team.assignment_id)
        if team.save
          fetch_team_and_participants team
        else
          render json: team.errors, status: :unprocessable_entity
        end
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity 
      end
    end
  end
end
