class TeamsParticipantsController < ApplicationController
  # Allow duty updation for a team if current user is student, else require TA or above privileges.
  def action_allowed?
    case params[:action]
    when 'update_duty'
      current_user_has_student_privileges?
    else
      current_user_has_ta_privileges?
    end
  end

  # Updates the duty (role) assigned to a participant in a team.
  def update_duty
    team_participant = TeamsParticipant.find_by(id: params[:teams_participant_id])

    # FIRST, check existence
    unless team_participant
      render json: { error: "Couldn't find TeamsParticipant" }, status: :not_found and return
    end

    # THEN, verify participant belongs to current user
    unless team_participant.participant.user_id == current_user.id
      render json: { error: 'You are not authorized to update duty for this participant' }, status: :forbidden and return
    end

    duty_id = params.dig(:teams_participant, :duty_id) || params.dig("teams_participant", "duty_id")
    team_participant.update(duty_id: duty_id)
    render json: { message: "Duty updated successfully" }, status: :ok
  end

  # Displays a list of all participants in a specific team.
  def list_participants
    # Retrieve the team from the database using the provided ID parameter.
    current_team = Team.find_by(id: params[:id])

    # If no team is found, return a 404 error with an appropriate error message.
    if current_team.nil?
      render json: { error: "Couldn't find Team" }, status: :not_found and return
    end

    # Fetch all team participant records associated with the current team.
    team_participants = TeamsParticipant.where(team_id: current_team.id)

    # Determine whether this team belongs to an assignment or a course
    # Determine context based on type column
    if current_team.type == "AssignmentTeam"
      context_key = :assignment
      context_value = current_team.assignment
    elsif current_team.type == "CourseTeam"
      context_key = :course
      context_value = current_team.course
    else
      render json: { error: "Invalid team type" }, status: :unprocessable_entity and return
    end

    # Build and return a single JSON response with common structure
    render json: {
      team_participants: team_participants,
      team: current_team,
      context_key => context_value
    }, status: :ok
  end

  # Adds Participant to a team
  def add_participant
    # First Check if Participant exists
    # Look up the User record based on the provided name parameter.
    user = User.find_by(name: params[:name].strip) || (render(json: { error: "User not found" }, status: :not_found) and return)
    # Find the Participant associated with the user, or return not found error
    participant = Participant.find_by(user_id: user.id) || (render(json: { error: "Couldn't find Participant" }, status: :not_found) and return)

    # Check if Team exists
    current_team = Team.find(params[:id])
    unless current_team
      render json: { error: "Couldn't find Team" }, status: :not_found and return
    end

    # Validate if participant can join a team
    validation_result = current_team.can_participant_join_team?(participant)

    unless validation_result[:success]
      Rails.logger.info "Validation error: #{validation_result[:error]}"
      render json: { error: validation_result[:error] }, status: :unprocessable_entity and return
    end

    # This line adds a participant to the current team
    result = current_team.add_member(participant)

    if result[:success]
      render json: { message: "Participant added successfully." }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end

  end

  # Removes one or more participants from a team.
  def delete_participants
    # Check if Team exists first
    current_team = Team.find_by(id: params[:id])
    unless current_team
      render json: { error: "Couldn't find Team" }, status: :not_found and return
    end

    # Extract participant IDs from payload
    participant_record_ids = params.dig(:payload, :item) || params.dig("payload", "item") || []

    if participant_record_ids.blank?
      render json: { error: "No participants selected" }, status: :ok and return
    end

    # Ensure we only delete participants belonging to the specified team
    TeamsParticipant.where(team_id: current_team.id, id: participant_record_ids).delete_all

    message = participant_record_ids.length == 1 ? "Participant removed successfully" : "Participants deleted successfully"
    render json: { message: message }, status: :ok

  end

end
