class Api::V1::InvitationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found
  before_action :set_invitation, only: %i[show update destroy]

  # GET /api/v1/invitations
  def index
    @invitations = Invitation.all
    render json: @invitations, status: :ok
  end

  # POST /api/v1/invitations/
  def create
    params[:invitation][:reply_status] ||= InvitationValidator::WAITING_STATUS
    @invitation = Invitation.invitation_factory(invite_params)
    if @invitation.save
      @invitation.send_invite_email
      render json: @invitation, status: :created
    else
      render json: { error: @invitation.errors[:base]}, status: :unprocessable_entity
    end
  end

  # GET /api/v1/invitations/:id
  def show
    render json: @invitation, status: :ok
  end

  # PATCH /api/v1/invitations/:id
  def update
    case params[:reply_status]
    when InvitationValidator::ACCEPT_STATUS
      result = @invitation.accept_invitation
      if result[:success]
        render json: { success: true, message: result[:message], invitation: @invitation}, status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    when InvitationValidator::REJECT_STATUS
      @invitation.decline_invitation
      render json: { success: true, message: "Invitation rejected successfully", invitation: @invitation}, status: :ok
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/invitations/:id
  def destroy
    @invitation.retract_invitation
    render json: { message: "Invitation retracted successfully." }, status: :ok

  rescue ActiveRecord::RecordNotFound
    render json: { error: "Invitation not found." }, status: :not_found
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { error: "Failed to retract invitation: #{e.record.errors.full_messages.to_sentence}" },
          status: :unprocessable_entity
  rescue => e
    render json: { error: "Unexpected error: #{e.message}" }, status: :internal_server_error
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
    params.require(:invitation).permit(:id, :assignment_id, :reply_status).merge(from_team: inviter_team, to_participant: invitee_participant)
  end

  # helper method used when invite is not found
  def invite_not_found
    render json: { error: "Invitation not found" }, status: :not_found
  end

  # helper method used to fetch invitation from its id
  def set_invitation
    @invitation = Invitation.find(params[:id])
  end

  def inviter_team
    inviter_participant = AssignmentParticipant.find_by(user: current_user)    
    inviter_participant.team
  end

  def invitee_participant
    invitee_user = User.find_by(name: params[:username])
    unless invitee_user
      render json: { error: "Participant with #{params[:username]} not found" }, status: :not_found
    end
    AssignmentParticipant.find_by(parent_id: params[:assignment_id], user: invitee_user)
  end
end
