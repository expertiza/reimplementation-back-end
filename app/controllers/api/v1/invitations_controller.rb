class Api::V1::InvitationsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :invite_not_found

  # GET /api/v1/invitations
  def index
    @invitations = Invitation.all
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched all invitations.", request)
    render json: @invitations, status: :ok
  end

  # POST /api/v1/invitations/
  def create
    params[:invitation][:reply_status] ||= InvitationValidator::WAITING_STATUS
    @invitation = Invitation.invitation_factory(invite_params)
    if @invitation.save
      @invitation.send_invite_email
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Created invitation with ID: #{@invitation.id}.", request)
      render json: @invitation, status: :created
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to create invitation. Errors: #{@invitation.errors.full_messages.join(', ')}", request)
      render json: { error: @invitation.errors }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/invitations/:id
  def show
    @invitation = Invitation.find(params[:id])
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched invitation with ID: #{@invitation.id}.", request)
    render json: @invitation, status: :ok
  end

  # PATCH /api/v1/invitations/:id
  def update
    @invitation = Invitation.find(params[:id])
    case params[:reply_status]
    when InvitationValidator::ACCEPT_STATUS
      @invitation.accept_invitation(nil)
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Accepted invitation with ID: #{@invitation.id}.", request)
      render json: @invitation, status: :ok
    when InvitationValidator::REJECT_STATUS
      @invitation.decline_invitation(nil)
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Rejected invitation with ID: #{@invitation.id}.", request)
      render json: @invitation, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Invalid reply status for invitation with ID: #{@invitation.id}.", request)
      render json: @invitation.errors, status: :unprocessable_entity
    end

  end

  # DELETE /api/v1/invitations/:id
  def destroy
    @invitation = Invitation.find(params[:id])
    @invitation.retract_invitation(nil)
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Deleted invitation with ID: #{@invitation.id}.", request)
    render nothing: true, status: :no_content
  end

  # GET /invitations/:user_id/:assignment_id
  def invitations_for_user_assignment
    begin
      @user = User.find(params[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "User not found with ID: #{params[:user_id]}. Error: #{e.message}", request)
      render json: { error: e.message }, status: :not_found
      return
    end

    begin
      @assignment = Assignment.find(params[:assignment_id])
    rescue ActiveRecord::RecordNotFound => e
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found with ID: #{params[:assignment_id]}. Error: #{e.message}", request)
      render json: { error: e.message }, status: :not_found
      return
    end

    @invitations = Invitation.where(to_id: @user.id).where(assignment_id: @assignment.id)
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched invitations for user ID: #{@user.id} and assignment ID: #{@assignment.id}.", request)
    render json: @invitations, status: :ok
  end

  private

  # This method will check if the invited user is a participant in the assignment.
  # Currently there is no association between assignment and users therefore this method is not implemented yet.
  def check_participant_before_invitation; end

  # only allow a list of valid invite params
  def invite_params
    params.require(:invitation).permit(:id, :assignment_id, :from_id, :to_id, :reply_status)
  end

  # helper method used when invite is not found
  def invite_not_found
    ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Invitation not found with ID: #{params[:id]}.", request)
    render json: { error: "Invitation with id #{params[:id]} not found" }, status: :not_found
  end

end
