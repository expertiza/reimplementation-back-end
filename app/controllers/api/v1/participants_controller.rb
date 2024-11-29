class Api::V1::ParticipantsController < ApplicationController
  # Return a list of participants
  # GET /participants
  def index; end

  # Return a specified participant
  # GET /participants/:id
  def show; end

  # Create a participant
  # POST /participants
  def create; end

  # Update the permissions of a participant
  # PATCH /participants/:id/permissions
  def update_permissions; end

  # Update the handle of a participant
  # PATCH /participants/:id/handle
  def update_handle; end

  # Delete a specified participant
  # DELETE /participants/:id
  def destroy; end

  # Permitted parameters for creating or updating a Participant object
  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id, :can_submit, :can_review, :handle,
                                        :permission_granted, :join_team_request_id, :team_id, :topic,
                                        :current_stage, :stage_deadline)
  end
end
