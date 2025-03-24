class Api::V1::TeamsParticipantsController < ApplicationController
  # Allow duty updation for a team if current user is student, else require TA or above privileges.
  def action_allowed?
    if %w[update_duties].include? params[:action]
      has_privileges_of?('Student')
    else
      has_privileges_of?('Teaching Assistant')
    end
  end

  # Updates the duty (role) assigned to a participant in a team.
  def update_duties
    team_participant = TeamParticipant.find(params[:team_participant_id])
    team_participant.update_attribute(:duty_id, params[:team_participant]['duty_id'])
    render json: { message: "Duty updated successfully" }, status: :ok
  end

  # Displays a list of all participants in a specific team.
  def list_participants
    current_team = Team.find_by(id: params[:id])
    if current_team.nil?
      render json: { error: "Couldn't find Team" }, status: 404 and return
    end

    associated_assignment_or_course = Assignment.find_by(id: current_team.assignment_id)
    if associated_assignment_or_course.nil?
      render json: { error: "Couldn't find Assignment or Course for this team" }, status: 404 and return
    end

    team_participants = TeamParticipant.where(team_id: current_team.id)
    render json: {
      team_participants: team_participants,
      team: current_team,
      assignment: associated_assignment_or_course
    }, status: 200
  end

  # Adds a new participant to a team after validation.
  def add_participant
    find_participant = find_participant_by_name
    unless find_participant
      render json: { error: "Couldn't find User" }, status: :not_found and return
    end

    current_team = Team.find(params[:id])
    if validate_participant_and_team(find_participant, current_team)
      if current_team.add_participants_with_validation(find_participant, current_team.assignment_id)[:success]
        undo_link("The participant \"#{find_participant.name}\" has been successfully added to \"#{current_team.name}\".")
      else
        flash[:error] = 'This team already has the maximum number of members.'
      end
    end
    redirect_to action: 'list_participants', id: params[:id]
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

  private

  def find_participant_by_name
    User.find_by(name: params[:user][:name].strip)
  end

  def validate_participant_and_team(participant, team)
    validation_result = if team.assignment_id.present?
                          assignment = Assignment.find_by(id: team.assignment_id)
                          if assignment
                            assignment.valid_team_participant?(participant, team.assignment_id)
                          else
                            { success: false, error: "Assignment not found" }
                          end
                        else
                          { success: false, error: "Invalid team assignment" }
                        end

    return false unless validation_result[:success]
    true
  end

  def participant_not_found_error
    nil
  end

  def non_participant_error(find_participant, parent_id, model)
    urlParticipantList = url_for controller: 'participants', action: 'list', id: parent_id, model: model, authorization: 'participant'
    "\"#{find_participant.name}\" is not a participant of the current assignment. Please <a href=\"#{urlParticipantList}\">add</a> this user before continuing."
  end
end
