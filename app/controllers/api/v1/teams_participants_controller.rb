class Api::V1::TeamsParticipantsController < ApplicationController
  # Allow duty updation for a team if current user is student, else require TA or above privileges.
  def action_allowed?
    case params[:action]
    when 'update_duty'
      has_privileges_of?('Student') # Only checks role here
    else
      has_privileges_of?('Teaching Assistant')
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

    # team_participant.update(duty_id: params[:team_participant]['duty_id'])
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

    # Check if the current team is associated with an assignment.
    # This applies to an AssignmentTeam.
    if current_team.respond_to?(:assignment) && current_team.assignment.present?
      render json: {
        team_participants: team_participants,    # List of team participants.
        team: current_team,                        # The team information.
        assignment: current_team.assignment        # The associated assignment.
      }, status: :ok

      # Otherwise, check if the team is associated with a course.
      # This applies to a CourseTeam.
    elsif current_team.respond_to?(:course) && current_team.course.present?
      render json: {
        team_participants: team_participants,    # List of team participants.
        team: current_team,                        # The team information.
        course: current_team.course                # The associated course.
      }, status: :ok

      # If the team is neither associated with an assignment nor a course,
      # return an error message indicating the team is misconfigured.
    else
      render json: { error: "Team is neither associated with an assignment nor a course" },
             status: :not_found and return
    end
  end


  # Adds Participant to a team
  def add_participant
    # First Check if Participant exists
    #
    # Look up the User record based on the provided name parameter.
    # The `strip` method removes any extra whitespace.
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
    # Retrieve the payload using string keys and convert each ID to an integer.
    item_ids = if params["payload"] && params["payload"]["item"]
                 Array(params["payload"]["item"]).map(&:to_i)
               else
                 []
               end

    # If no IDs were provided in the payload, return early.
    if item_ids.blank?
      render json: { error: "No participants selected" }, status: :ok and return
    end

    # Use delete_all to remove records directly (bypassing callbacks).
    TeamsParticipant.where(id: item_ids).delete_all

    # Determine the appropriate message based on the number of deletions.
    message = item_ids.length == 1 ? "Participant removed successfully" : "Participants deleted successfully"
    render json: { message: message }, status: :ok
  end








end
