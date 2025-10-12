class Api::V1::StudentTeamsController < ApplicationController

    #  team is gaining or losing a member
    def team
        @team ||= if params[:student_id].present? && student.present?
                    student.team 
                  else
                    AssignmentTeam.find_by(id:params[:team_id])
                  end
    end

    attr_writer :team

    # student is someone who is joining or leaving a team 
    def student
        @student ||= AssignmentParticipant.find_by(id: params[:student_id])
    end

    attr_writer :student

    before_action :team, only: %i[edit update]
    before_action :student, only: %i[view update edit create leave]

    def action_allowed?
        # this can be accessed only by the student and so someone with atleast TA priviliges wont be able to access this controller
        # also the current logged in user can view its relevant team and not other student teams.
        if current_user_has_ta_privileges? || @student.nil? || !current_user_has_id?(student.user_id)
            render json: { error: "You do not have permission to perform this action." }, status: :forbidden
        end
        return true
    end

    # GET /student_teams/view?student_id=${studentId}`
    # it will give the team details of which the student is a member 
    def view
        render json: team, status: :ok
    end

    def update
        matching_teams = AssignmentTeam.where(name: params[:team][:name], parent_id: team.parent_id)

        if matching_teams.empty?
            if team.update(name: params[:team][:name])
            render json: { message: "Team updated successfully", team: team, success: true }, status: :ok
            else
            render json: { error: team.errors.full_messages }, status: :unprocessable_entity
            end

        else
            Rails.logger.info(
            "[StudentTeamsController] User=#{current_user.name} tried to update team name to '#{params[:team][:name]}' but it already exists"
            )
            render json: { error: "That team name is already in use." }, status: :unprocessable_entity
        end
    end

    # method to remove the student from the current team. 
    # PUT /student_teams/leave?student_id=${studentId}
    def leave_team
        print "leaving the current team #{params[:student_id]}"
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