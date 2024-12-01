class Api::V1::StudentTeamsController < ApplicationController
    # include AuthorizationHelper
    # autocomplete :user, :name
    rescue_from ActiveRecord::RecordNotFound, with: :user_not_found
    rescue_from ActionController::ParameterMissing, with: :parameter_missing

    before_action :set_team, only: %i[show edit update remove_participant]
    before_action :set_student, only: %i[view update create remove_participant]
    
    # GET /api/v1/student_teams?student_id=&team_id=
    # Retrieve StudentTeams by query parameters
    def index
      # if params[:student_id].nil?
      #   render json: { error: 'Student ID is required!' }, status: :unprocessable_entity
      # elsif params[:team_id].nil?
        @student_teams = AssignmentTeam.all # check for mentored teams as well
        render json: @student_teams, status: :ok
      # else
      #   @student_teams = AssignmentTeam.where(student_id: params[:student_id], team_id: params[:team_id])
      #   render json: @student_teams, status: :ok
      # end
    end

    # GET /student_teams/:id
    # Show details of a specific team
    def show
      assignment = AssignmentTeam.find(params[:id])
      render json: assignment, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
    end
  
    def team_name1 # Fix this later
      "Team_name:" + Time.now.to_s
    end

    def create
      existing_teams = AssignmentTeam.where name: params[:team][:name], assignment_id: @student.assignment_id
      # check if the team name is in use
      team_name = params[:team][:name] || team_name1
      if existing_teams.empty?
        parent = Assignment.find_by id: @student.assignment_id
        if parent != nil && parent.auto_assign_mentor
          team = AssignmentTeam.new(name: team_name, assignment_id: @student.assignment_id) # Create mentored team for this
        else
          team = AssignmentTeam.new(name: team_name, assignment_id: @student.assignment_id)
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

    # PATCH/PUT /student_teams/:id
    # Updates team name or other attributes
    def update
      matching_teams = AssignmentTeam.where(name: params[:team][:name], parent_id: @team.assignment.id)
      if matching_teams.length.zero?
        if @team.update(name: params[:team][:name])
          render json: { message: "The team: \"#{@team.name}\" has been updated successfully." }, status: :ok
        else
          render json: { error: @team.errors.full_messages }, status: :unprocessable_entity
        end
      elsif matching_teams.length == 1 && matching_teams.name == @team.name
        render json: { message: "The team: \"#{@team.name}\" has been updated successfully." }, status: :ok
      else
        render json: { error: 'That team name is already in use.' }, status: :unprocessable_entity
      end
    end

    # DELETE /student_teams/:id
    def destroy
      begin
        @bookmark = Bookmark.find(params[:id])
        @bookmark.delete
      rescue ActiveRecord::RecordNotFound
          render json: $ERROR_INFO.to_s, status: :not_found and return
      end
    end

    # DELETE /student_teams/:id/remove_participant
    def remove_participant
      Team.remove_team_user(team_id: params[:team_id], user_id: @student.user_id)
      Invitation.where(from_id: @student.user_id, assignment_id: @student.parent_id).destroy_all
      render json: { message: 'Participant removed successfully.' }, status: :ok
    end

    def hellothere
      assignment_team = AssignmentTeam.find_by(name: 'example_team')
      if assignment_team
        render json: { team_name: assignment_team.name, status: 'found' }, status: :ok
      else
        render json: { error: 'Team not found' }, status: :not_found
      end
    end

    private

    def set_team
      @team = AssignmentTeam.find(params[:team_id])
    end

    def set_student
      @student = AssignmentParticipant.find(params[:student_id])
    end

    # def team_params
    #   params.require(:team).permit(:name)
    # end

    # def student_params
    #   params.require(:student).permit(:user_id, :assignment_id)
    # end

    def parameter_missing(exception)
      render json: { error: "Parameter missing: #{exception.param}" }, status: :unprocessable_entity
    end
    
  end
  