class InvitationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found

  # GET /invitations
  def index
    @invitations = Invitation.all
    render json: @invitations, status: :ok
  end

  # POST /invitations/
  def create
    params[:invitation][:reply_status] ||= InvitationValidator::WAITING_STATUS
    @invitation = Invitation.invitation_factory(invite_params)
    if @invitation.save
      @invitation.send_invite_email
      render json: @invitation, status: :created
    else
      render json: { message: @invitation.errors , success: false}, status: :unprocessable_entity
    end
  end

  # GET /invitations/:id
  def show
    @invitation = Invitation.find(params[:id])
    render json: @invitation, status: :ok
  end

  # PATCH /invitations/:id
  def update
    @invitation = Invitation.find(params[:id])
    case params[:reply_status]
    when InvitationValidator::ACCEPT_STATUS
      @invitation.accept_invitation(nil)
      render json: @invitation, status: :ok
    when InvitationValidator::REJECT_STATUS
      @invitation.decline_invitation(nil)
      render json: @invitation, status: :ok
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end
  end

  # DELETE /invitations/:id
  def destroy
    @invitation = Invitation.find(params[:id])
    @invitation.retract_invitation(nil)
    render nothing: true, status: :no_content
  end

  def invitations_sent_to_participant
    begin
      @participant = AssignmentParticipant.find(params[:participant_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { message: e.message, success:false }, status: :not_found
      return
    end

    @invitations = Invitation.where(to_id: @participant.id, assignment_id: @participant.parent_id)
    render json: @invitations, status: :ok
  end

  def invitations_sent_by_team
    begin
      @team = AssignmentTeam.find(params[:team_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { message: e.message, success: false }, status: :not_found
      return
    end

    @invitations = Invitation.where(from_id: @team.id, assignment_id: @team.parent_id)
    render json: @invitations, status: :ok
  end


  private

  # only allow a list of valid invite params
  def invite_params
    params.require(:invitation).permit(:id, :assignment_id, :from_id, :to_id, :reply_status)
  end

  # helper method used when invite is not found
  def invite_not_found
    render json: { error: "Invitation with id #{params[:id]} not found" }, status: :not_found
  end

end
