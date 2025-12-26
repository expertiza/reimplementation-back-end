class StudentTeamsController < ApplicationController

    #  team is gaining or losing a member
    def team
        @team ||= if params[:student_id].present? && student.present?
                    TeamsParticipant.find_by(participant_id:student.id)&.team
                elsif params[:team_id].present?
                    AssignmentTeam.find_by(id:params[:team_id])
                  end
    end

    attr_writer :team

    # student is someone who is joining or leaving a team 
    def student
        @student ||= AssignmentParticipant.find_by(id: params[:student_id])
    end

    attr_writer :student

    before_action :team, :student, only: %i[view update leave_team]

    def action_allowed?
        # this can be accessed only by the student and so someone with atleast TA priviliges wont be able to access this controller
        # also the current logged in user can view only its relevant team and not other student teams.      
        if current_user_has_ta_privileges? || student.nil? || !current_user_has_id?(student.user_id)
            render json: { error: "You do not have permission to perform this action." }, status: :forbidden
        end        
        return true
    end

    # GET /student_teams/view?student_id=${studentId}`
    # Returns details of the team that the current student belongs to. 
    def view
        if @team.nil?
            render json: { assignment: AssignmentSerializer.new(student.assignment), team: nil, message: "You are not part of any team currently."}, status: :ok
        else
            render json: {assignment: AssignmentSerializer.new(student.assignment), team: TeamSerializer.new(@team)}, status: :ok
        end
    end

    # POST /student_teams/`
    def create
        # Checks for duplicate team names within the same assignment (by parent_id).
        matching_teams = AssignmentTeam.where(name: params[:team][:name], parent_id: params[:assignment_id])

        # no team with that name found - goes ahead and creates the team
        if matching_teams.empty?
            team = AssignmentTeam.new({ name: params[:team][:name], parent_id: params[:assignment_id]})
            if team.save
                # adding the student as the participant for the student_team just created
                team.add_participant(student)
                serialized_team = ActiveModelSerializers::SerializableResource.new(team, serializer: TeamSerializer).as_json
                render json: serialized_team.merge({ message: "Team created successfully", success: true }), status: :ok
            else
                render json: { error: team.errors.full_messages }, status: :unprocessable_entity
            end

        else
            # Returns an error if another team with the same name already exists.
            render json: { error: "#{params[:team][:name]} is already in use." }, status: :unprocessable_entity
        end
    end

    # Updates the name of the student's team.
    def update
        # Checks for duplicate team names within the same assignment (by parent_id).
        matching_teams = AssignmentTeam.where(name: params[:team][:name], parent_id: team.parent_id)

        # no team with that name found - goes ahead and saves the new name
        if matching_teams.empty?
            if team.update(name: params[:team][:name])
                serialized_team = ActiveModelSerializers::SerializableResource.new(team, serializer: TeamSerializer).as_json
                render json: serialized_team.merge({ message: "Team updated successfully", success: true }), status: :ok
            else
                render json: { error: team.errors.full_messages }, status: :unprocessable_entity
            end

        else
            # Returns an error if another team with the same name already exists.
            render json: { error: "#{params[:team][:name]} is already in use." }, status: :unprocessable_entity
        end
    end

    # method to remove the student from the current team. 
    # PUT /student_teams/leave?student_id=${studentId}
    def leave_team
        @team.remove_participant(@student)
        render json: { message: "Left the team successfully", success: true }, status: :ok
    end

    # used to check student team requirements
    def student_team_requirements_met?
        # checks if the student has a team
        return false if @student.team.nil?
        # checks that the student's team has a topic
        return false if @student.team.topic.nil?
        true
    end
end