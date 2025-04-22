class Api::V1::TeamsParticipantsController < ApplicationController
  # Allow duty updation for a team if current user is student, else require TA or above privileges.
  def action_allowed?
    case params[:action]
    when 'update_duty'
      has_privileges_of?('Student')
    else
      has_privileges_of?('Teaching Assistant')
    end
  end

  # Updates the duty (role) assigned to a participant in a team.
  def update_duty
    tp = TeamsParticipant.find_by(id: params[:teams_participant_id])
    return render json: { error: "Couldn't find TeamsParticipant" }, status: :not_found unless tp

    unless tp.participant.user_id == current_user.id
      return render json: { error: 'You are not authorized to update duty for this participant' },
                    status: :forbidden
    end

    duty_id = params.dig(:teams_participant, :duty_id) || params.dig('teams_participant', 'duty_id')
    tp.update!(duty_id: duty_id)
    render json: { message: "Duty updated successfully" }, status: :ok
  end

  # Displays a list of all participants in a specific team.
  def list_participants
    team = Team.find_by(id: params[:id])
    return render json: { error: "Couldn't find Team" }, status: :not_found unless team

    tps = TeamsParticipant.where(team_id: team.id)

    if team.assignment.present?
      render json: { team_participants: tps, team: team, assignment: team.assignment }, status: :ok
    elsif team.course.present?
      render json: { team_participants: tps, team: team, course: team.course }, status: :ok
    else
      render json: { error: "Team is neither associated with an assignment nor a course" },
             status: :not_found
    end
  end

  # Adds a Participant to a team.
  def add_participant
    user = User.find_by(name: params[:name].to_s.strip)
    return render json: { error: "User not found" }, status: :not_found unless user

    participant = Participant.find_by(user_id: user.id)
    return render json: { error: "Couldn't find Participant" }, status: :not_found unless participant

    team = Team.find_by(id: params[:id])
    return render json: { error: "Couldn't find Team" }, status: :not_found unless team

    if team.full?
      return render json: { error: "Participant cannot be added to this team" },
                    status: :unprocessable_entity
    end

    TeamsParticipant.create!(team_id: team.id, participant_id: participant.id)
    render json: { message: "Participant added successfully." }, status: :ok
  end

  # Removes one or more participants from a team.
  def delete_participants
    team = Team.find_by(id: params[:id])
    return render json: { error: "Couldn't find Team" }, status: :not_found unless team

    ids = params.dig(:payload, :item) || params.dig('payload', 'item') || []
    return render json: { error: "No participants selected" }, status: :ok if ids.empty?

    TeamsParticipant.where(team_id: team.id, id: ids).delete_all
    msg = ids.size == 1 ? "Participant removed successfully" : "Participants deleted successfully"
    render json: { message: msg }, status: :ok
  end
end
