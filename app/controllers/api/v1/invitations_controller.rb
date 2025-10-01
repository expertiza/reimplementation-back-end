class Api::V1::InvitationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found

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
      render json: { error: @invitation.errors }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/invitations/:id
  def show
    @invitation = Invitation.find(params[:id])
    render json: @invitation, status: :ok
  end

  # PATCH /api/v1/invitations/:id
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

  # DELETE /api/v1/invitations/:id
  def destroy
    @invitation = Invitation.find(params[:id])
    @invitation.retract_invitation(nil)
    render nothing: true, status: :no_content
  end

  def invitations_sent_to_participant
    print "hello"
  end

  def invitations_sent_by_participant
  
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

  # only allow a list of valid invite params
  def invite_params
    params.require(:invitation).permit(:id, :assignment_id, :from_id, :to_id, :reply_status)
  end

  # helper method used when invite is not found
  def invite_not_found
    render json: { error: "Invitation with id #{params[:id]} not found" }, status: :not_found
  end

end
