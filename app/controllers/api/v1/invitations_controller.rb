class Api::V1::InvitationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found

  # GET /api/v1/invitations
  def index
    @invitations = Invitation.all
    render json: @invitations
  end

  # POST /api/v1/invitations/
  def create
    params[:invitation][:reply_status] ||= Invitation::WAITING_STATUS
    @invitation = Invitation.invitation_factory(invite_params)
    if @invitation.save
      @invitation.send_invite_email
      render json: @invitation, status: :created
    else
      render json: { error: @invitation.errors }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/invitations/:id
  def show
    @invitation = Invitation.find(params[:id])
    render json: @invitation, status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # PATCH /api/v1/invitations/:id
  def update
    @invite_id = params[:id]
    @invitation = Invitation.find(@invite_id)
    case params[:reply_status]
    when Invitation::ACCEPT_STATUS
      @invitation.accept_invitation( nil)
      render json: @invitation, status: :ok
    when Invitation::REJECT_STATUS
      @invitation.decline_invitation( nil)
      render json: @invitation, status: :ok
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end

  end

  # DELETE /api/v1/invitations/:id
  def destroy
    @invitation = Invitation.find(params[:id])
    @invitation.retract_invitation(nil)
    render nothing: true, status: :no_content
  end

  # GET /invitations/:user_id/:assignment_id
  def invitations_for_user_assignment
    begin
      @user = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
      return
    end

    begin
      @assignment = Assignment.find(params[:assignment_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
      return
    end

    @invitations = Invitation.where(to_id: @user.id).where(assignment_id: @assignment.id)
    render json: @invitations, status: :ok
  end

  private

  # This method will check if the invited user exists.Additionally, this
  # method will also check if the sender himself is participating in the given assignment
  # before they can send an invitation.
  def check_invited_user_before_invitation; end

  # This method will check if the invited user is a participant in the assignment.
  # Currently there is no association between assignment and users therefore this method is not implemented yet.
  def check_participant_before_invitation; end

  # This method will check if the team meets the joining requirement before sending an invite.
  # NOTE: This method depends on TeamUser and AssignmentTeam, which is not implemented yet.
  def check_team_before_invitation; end

  # This method will check if the team meets the joining requirements when an invitation
  # is being accepted for example check if the invite's team is still existing,
  # and have available slot to add the invitee.
  # NOTE: This method depends on AssignmentParticipant and AssignmentTeam
  # which is not implemented yet.
  def check_team_before_accept; end

  # only allow a list of valid invite params
  def invite_params
    params.require(:invitation).permit(:id, :assignment_id, :from_id, :to_id, :reply_status)
  end

  # helper method used when invite is not found
  def invite_not_found
    render json: { error: "Invitation with id #{params[:id]} not found" }, status: :not_found
  end

end
