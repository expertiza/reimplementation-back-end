class Api::V1::StudentTeamsController < ApplicationController

    #  team is gaining or losing a member
    def team
        @team ||= if params[:student_id].present?
                    student.team 
                  else
                    AssignmentTeam.find(params[:team_id])
                  end
    end

    attr_writer :team

    # student is someone who is joining or leaving a team 
    def student
        @student ||= AssignmentParticipant.find(params[:student_id])
    end

    attr_writer :student

    before_action :team, only: %i[edit update]
    before_action :student, only: %i[view update edit create remove_participant]

    def action_allowed?
        # note, this code replaces the following line that cannot be called before action allowed?
        return false unless current_user_has_student_privileges?

        case action_name
        when 'view'
        current_user_has_id? student.user_id
        when 'create'
        current_user_has_id? student.user_id
        when 'edit', 'update'
        current_user_has_id? student.user_id
        else
        true
        end
    end


    def view
        # it will give the team details of which the student is a member 
        render json: team, status: :ok
    end

    def create
        existing_teams = AssignmentTeam.where name: params[:team][:name], parent_id: student.parent_id
        # check if the team name is in use
        if existing_teams.empty?
        if params[:team][:name].blank?
            flash[:notice] = 'The team name is empty.'
            ExpertizaLogger.info LoggerMessage.new(controller_name, current_user.name, 'Team name missing while creating team', request)
            redirect_to view_student_teams_path student_id: student.id
            return
        end
        parent = AssignmentNode.find_by node_object_id: student.parent_id
        # E2351- a decision needs to be made here whether to create an AssignmentTeam or MentoredTeam depending on assignment settings
        if parent.assignment != nil && parent.assignment.auto_assign_mentor
            team = MentoredTeam.new(name: params[:team][:name], parent_id: student.parent_id)
        else
            team = AssignmentTeam.new(name: params[:team][:name], parent_id: student.parent_id)
        end
        team.save
        #
        TeamNode.create parent_id: parent.id, node_object_id: team.id
        user = User.find(student.user_id)
        team.add_member(user, team.parent_id)
        team_created_successfully(team)
        redirect_to view_student_teams_path student_id: student.id

        else
        flash[:notice] = 'That team name is already in use.'
        ExpertizaLogger.error LoggerMessage.new(controller_name, current_user.name, 'Team name being created was already in use', request)
        redirect_to view_student_teams_path student_id: student.id
        end
    end

    def edit; end

    def update
        matching_teams = AssignmentTeam.where(name: params[:teamName], parent_id: team.parent_id)

        if matching_teams.empty?
            if team.update(name: params[:teamName])
            render json: { message: "Team updated successfully", team: team, success: true }, status: :ok
            else
            render json: { error: team.errors.full_messages }, status: :unprocessable_entity
            end

        else
            Rails.logger.info(
            "[StudentTeamsController] User=#{current_user.name} tried to update team name to '#{params[:teamName]}' but it already exists"
            )
            render json: { error: "That team name is already in use." }, status: :unprocessable_entity
        end
    end


    # used to check student team requirements
    def student_team_requirements_met?
        # checks if the student has a team
        return false if @student.team.nil?
        # checks that the student's team has a topic
        return false if @student.team.topic.nil?

        # checks that the student has selected some topics
        @student.assignment.topics?
    end
end