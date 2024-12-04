module StudentTeamsHelper
    private
    
    def set_team
      @team = AssignmentTeam.find(params[:team_id])
    end
  
    def all_teams
      AssignmentTeam.all
    end 
  
    def current_team
      AssignmentTeam.find(params[:id])
    end
  
    def set_student
      @student = AssignmentParticipant.find(params[:student_id])
    end
  
    def generate_team_name
      loop do
        suffix = rand(1..999)
        team_name = "Team_#{suffix}"
        break team_name unless AssignmentTeam.exists?(name: team_name)
      end
    end

    def record_not_found(exception)
      if exception.model == 'AssignmentTeam'
        render json: { error: 'Team id not found.' }, status: :not_found
      elsif exception.model == 'AssignmentParticipant'
        render json: { error: 'User id not found.' }, status: :not_found
      else
        render json: { error: 'Record not found.' }, status: :not_found
      end
    end
  
    def parameter_missing(exception)
      render json: { error: "Parameter missing: #{exception.param}" }, status: :unprocessable_entity
    end

    def fetch_team_and_participants(team, status = :ok)
      participants = team.assignment_participants
      team_json = team.as_json
      team_json[:participants] = participants.map { |participant| { student_id: participant.id } }
      render json: team_json, status: status
    end

    def fetch_all_teams_and_participants(teams, status = :ok)
      teams = teams.map do |team|
        # Convert the team object to a JSON hash
        team_json = team.as_json
        # Append the participants to the team JSON hash
        team_json[:participants] = team.assignment_participants.map { |participant| { student_id: participant.id } }
        team_json
      end
      render json: { teams: teams }, status: status
    end
  end