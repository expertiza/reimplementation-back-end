class Api::V1::InvitationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found
  before_action :set_invitation, only: %i[show update destroy]
  before_action :invitee_participant, only: %i[create]

  def action_allowed?
    case params[:action]
    when 'invitations_sent_to_participant'
      @participant = AssignmentParticipant.find(params[:participant_id])
      unless current_user_has_id?(@participant.user_id)
        render json: { error: "You do not have permission to perform this action." }, status: :forbidden
      end
      return true 
    else
      return true
    end
  end

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
      render json: { success: true, message: "Invitation successfully sent to #{params[:username]}", invitation: @invitation}, status: :created
    else
      render json: { error: @invitation.errors[:base].first}, status: :unprocessable_entity
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
      # if the current invitation status is either accepted/rejected/retracted then the invitation is no longer valid.
      unless @invitation.reply_status.eql?(InvitationValidator::WAITING_STATUS)
        render json: { error: "Sorry, the invitation is no longer valid" }, status: :unprocessable_entity
        return
      end
      result = @invitation.accept_invitation
      if result[:success]
        render json: { success: true, message: result[:message], invitation: @invitation}, status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    when InvitationValidator::DECLINED_STATUS
      @invitation.decline_invitation
      render json: { success: true, message: "Invitation rejected successfully", invitation: @invitation}, status: :ok
    when InvitationValidator::RETRACT_STATUS
      @invitation.retract_invitation
      render json: { success: true, message: "Invitation retracted successfully", invitation: @invitation}, status: :ok
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/invitations/:id
  def destroy
    @invitation.destroy!
    render json: { success:true, message: "Invitation deleted successfully." }, status: :ok

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
    params.require(:invitation).permit(:id, :assignment_id, :reply_status).merge(from_team: inviter_team, to_participant: invitee_participant, from_participant: inviter_participant)
  end

  # helper method used when invite is not found
  def invite_not_found
    render json: { error: "Invitation not found" }, status: :not_found
  end

  # helper method used to fetch invitation from its id
  def set_invitation
    @invitation = Invitation.find(params[:id])
  end

  def inviter_participant
    AssignmentParticipant.find_by(user: current_user)    
  end

  # the team of the inviter at the time of sending invitation
  def inviter_team
    inviter_participant.team
  end

  def invitee_participant
    invitee_user = User.find_by(name: params[:username])
    unless invitee_user
      render json: { error: "Participant with username #{params[:username]} not found" }, status: :not_found
      return
    end
    invitee = AssignmentParticipant.find_by(parent_id: params[:assignment_id], user: invitee_user)
    unless invitee
      render json: { error: "Participant with username #{params[:username]} not found" }, status: :not_found
      return
    end
    invitee
  end
end
