class Api::V1::StudentTeamsController < ApplicationController
    include AuthorizationHelper
    autocomplete :user, :name

    before_action :set_team, only: %i[show edit update remove_participant]
    before_action :set_student, only: %i[view update create remove_participant]
    
    def action_allowed?
      # note, this code replaces the following line that cannot be called before action allowed?
      # E2476. modified the code to use smaller methods checking allowed actions
      return false unless current_user_has_student_privileges?
  
      case action_name
      when 'view'
        view_action_allowed?
      when 'create'
        create_action_allowed?
      when 'edit', 'update'
        edit_update_action_allowed?
      else
        false
      end
    end
  
    def controller_locale
      locale_for_student
    end

    # GET /api/v1/student_teams?student_id=&team_id=
    # Retrieve StudentTeams by query parameters
    def index
      if params[:student_id].nil?
        render json: { message: 'Student ID is required!' }, status: :unprocessable_entity
      elsif params[:team_id].nil?
        @student_teams = AssignmentTeam.where(student_id: params[:student_id])
        render json: @student_teams, status: :ok
      else
        @student_teams = AssignmentTeam.where(student_id: params[:student_id], team_id: params[:team_id])
        render json: @student_teams, status: :ok
      end
    end

    # GET /student_teams/:id
    # Show details of a specific team
    def show
      render json: @team, status: :ok
    end
  
    def view
      # View will check if send_invs and received_invs are set before showing
      # only the owner should be able to see those.
  
      return unless current_user_id? student.user_id
  
      @send_invs = Invitation.where from_id: student.user.id, assignment_id: student.assignment.id
      @received_invs = Invitation.where to_id: student.user.id, assignment_id: student.assignment.id, reply_status: 'W'
  
      @current_due_date = DueDate.current_due_date(@student.assignment.due_dates)
  
      # this line generates a list of users on the waiting list for the topic of a student's team,
      # E2476. modified if statement from checking a single method student_team_requirements_met to multiple smaller methods for SRP
      @users_on_waiting_list = (SignUpTopic.find(@student.team.topic).users_on_waiting_list if (student_has_team && student_team_has_topic? && student_has_selected_topic?)) 
      @teammate_review_allowed = DueDate.teammate_review_allowed(@student)
    end
  
    def mentor
       return unless current_user_id? student.user_id
       # Default return to views/student_team/mentor utilized
    end
  
    def create
      existing_teams = AssignmentTeam.where name: params[:team][:name], parent_id: student.parent_id
      # check if the team name is in use
      if existing_teams.empty?
        if params[:team][:name].blank?
          flash[:notice] = 'The team name is empty.'
          ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, 'Team name missing while creating team', request)
          redirect_to view_student_teams_path student_id: student.id
          return
        end
        parent = AssignmentNode.find_by node_object_id: student.parent_id
        if parent.assignment != nil && parent.assignment.auto_assign_mentor
          team = MentoredTeam.new(name: params[:team][:name], parent_id: student.parent_id)
        else
          team = AssignmentTeam.new(name: params[:team][:name], parent_id: student.parent_id)
        end
        team.save
        TeamNode.create parent_id: parent.id, node_object_id: team.id
        user = User.find(student.user_id)
        team.add_member(user, team.parent_id)
        redirect_to view_student_teams_path student_id: student.id
  
      else
        flash[:notice] = 'That team name is already in use.'
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, 'Team name being created was already in use', request)
        redirect_to view_student_teams_path student_id: student.id
      end
    end
  
    def edit; end

    # PATCH/PUT /student_teams/:id
    # Updates team name or other attributes
    def update
      matching_teams = AssignmentTeam.where(name: params[:team][:name], parent_id: @team.parent_id)
      if matching_teams.length.zero?
        if @team.update(name: params[:team][:name])
          render json: { message: "The team: \"#{@team.name}\" has been updated successfully." }, status: :ok
        else
          render json: { message: @team.errors.full_messages }, status: :unprocessable_entity
        end
      elsif matching_teams.length == 1 && matching_teams.name == team.name
        render json: { message: "The team: \"#{@team.name}\" has been updated successfully." }, status: :ok
      else
        flash[:notice] = 'That team name is already in use.'
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, 'Team name being updated to was already in use', request)
        render json: { message: 'That team name is already in use.' }, status: :unprocessable_entity
      end
    end
  
    def remove_participant
      # remove the record from teams_users table & delete team if there are no members
      Team.remove_team_user(team_id: params[:team_id], user_id: student.user_id)

      # remove all the sent invitations
      old_invites = Invitation.where from_id: student.user_id, assignment_id: student.parent_id
      old_invites.each(&:destroy)
      student.save
      redirect_to view_student_teams_path student_id: student.id
    end
  
    # This method is used to show the Author Feedback Questionnaire of current assignment
    def review
      @assignment = Assignment.find params[:assignment_id]
      redirect_to view_questionnaires_path id: @assignment.questionnaires.find_by(type: 'AuthorFeedbackQuestionnaire').id
    end
  
    # E2476. used to check student team requirements with a method student_team_requirements_met
    # We have broken it down into 3 smaller methods for SRP
  
    def student_has_team?
      !@student.team.nil?
    end
  
    def student_team_has_topic?
      !@student.team.topic.nil?
    end
  
    def student_has_selected_topic?
      @student.assignment.topics?
    end
  
    # E2476. broken action_allowed? method into 3 smaller methods for SRP 
  
    def view_action_allowed?
      if are_needed_authorizations_present?(params[:student_id], 'reader', 'reviewer', 'submitter')
        current_user_has_id? student.user_id
      else
        false
      end
    end
    
    def create_action_allowed?
      current_user_has_id? student.user_id
    end
    
    def edit_update_action_allowed?
      current_user_has_id? team.user_id
    end

    private

    def set_team
      @team = AssignmentTeam.find(params[:team_id])
    end

    def set_student
      @student = AssignmentParticipant.find(params[:student_id])
    end

    def team_params
      params.require(:team).permit(:name)
    end

    def student_params
      params.require(:student).permit(:user_id, :assignment_id)
    end
    
  end
  