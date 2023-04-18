class Api::V1::InvitationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found

  # GET /api/v1/invitations
  def index
    @invitations = Invitation.all
    render json: @invitations
  end

  # POST /api/v1/invitations/
  def create; end

  # GET /api/v1/invitations/:id
  def show; end

  # PATCH /api/v1/invitations/:id
  def update; end

  # DELETE /api/v1/invitations/:id
  def delete; end

  # GET /invitations/:user_id/:assignment_id
  def list_all_invitations_for_user_assignment; end

  private

  # This method will check if the invited user exists.
  def check_invited_user_before_invitation; end

  # This method will check if the invited user is a participant in the assignment.
  def check_participant_before_invitation; end

  # This method will check if the team meets the joining requirement before sending an invite.
  # NOTE: This method depends on TeamUser and AssignmentTeam, which is not implemented yet.
  def check_team_before_invitation; end

  # This method will check if the team meets the joining requirements
  # when an invitation is being accepted
  # NOTE: This method depends on AssignmentParticipant and AssignmentTeam
  # which is not implemented yet.
  def check_team_before_accept; end

  # only allow a list of valid invite params
  def invite_params; end

  # helper method used when invite is not found
  def invite_not_found; end

end
