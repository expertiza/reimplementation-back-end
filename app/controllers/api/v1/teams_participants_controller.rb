class Api::V1::TeamsParticipantsController < ApplicationController
  # Allow duty updation for a team if current user is student, else require TA or above privileges.
  def action_allowed?
    case params[:action]
    when 'update_duties'
      has_privileges_of?('Student') # Only checks role here
    else
      has_privileges_of?('Teaching Assistant')
    end
  end


  # Updates the duty (role) assigned to a participant in a team.
  def update_duties
    team_participant = TeamParticipant.find_by(id: params[:team_participant_id])

    # FIRST, check existence
    unless team_participant
      render json: { error: "Couldn't find TeamParticipant" }, status: :not_found and return
    end

    # THEN, verify participant belongs to current user
    unless team_participant.user_id == current_user.id
      render json: { error: 'You are not authorized to update duties for this participant' }, status: :forbidden and return
    end

    team_participant.update(duty_id: params[:team_participant]['duty_id'])
    render json: { message: "Duty updated successfully" }, status: :ok
  end


  # Displays a list of all participants in a specific team.
  def list_participants
    current_team = Team.find_by(id: params[:id])
    if current_team.nil?
      render json: { error: "Couldn't find Team" }, status: 404 and return
    end

    associated_assignment = Assignment.find_by(id: current_team.assignment_id)
    if associated_assignment.nil?
      render json: { error: "Couldn't find Assignment for this team" }, status: 404 and return
    end

    team_participants = TeamParticipant.where(team_id: current_team.id)
    render json: {
      team_participants: team_participants,
      team: current_team,
      assignment: associated_assignment
    }, status: 200
  end

  def add_participant
    find_participant = User.find_by(name: params[:user][:name].strip)
    unless find_participant
      render json: { error: "Couldn't find Participant" }, status: :not_found and return
    end

    current_team = Team.find(params[:id])

    assignment = Assignment.find_by(id: current_team.assignment_id)
    validation_result = assignment.can_participant_join_team_for_assignment?(find_participant, assignment.id)

    unless validation_result[:success]
      Rails.logger.info "Validation error: #{validation_result[:error]}"
      render json: { error: validation_result[:error] }, status: :unprocessable_entity and return
    end

    result = current_team.add_participants_with_validation(find_participant)

    if result[:success]
      # undo_link("Participant added successfully.")
      render json: { message: "Participant added successfully." }, status: :ok
      # redirect_to action: 'list_participants', id: params[:id]
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end



  # Removes a participant from a team.
  def delete_participant
    team_participant = TeamParticipant.find_by(id: params[:id])
    if team_participant.nil?
      render json: { error: "Couldn't find TeamParticipant" }, status: 404 and return
    end
    team_participant.destroy
    render json: { message: "Participant removed successfully" }, status: 200
  end

  # Deletes selected participants from a team.
  def delete_selected_participants
    item_ids = params.dig(:payload, :item) || params.dig("payload", "item") || params[:item]
    if item_ids.blank?
      render json: { error: "No participants selected" }, status: 200 and return
    end

    item_ids.each do |item_id|
      team_participant = TeamParticipant.find_by(id: item_id)
      team_participant&.destroy
      Rails.logger.debug "Deleted TeamParticipant with id: #{item_id}"
    end

    render json: { message: "Participants deleted successfully" }, status: 200
  end

end
