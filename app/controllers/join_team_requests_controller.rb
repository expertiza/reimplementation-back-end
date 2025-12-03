class JoinTeamRequestsController < ApplicationController
  # Constants used to indicate status for the request
  PENDING = 'PENDING'
  DECLINED = 'DECLINED'
  ACCEPTED = 'ACCEPTED'

  # This filter runs before the create action, checking if the team is full
  before_action :check_team_status, only: [:create]

  # This filter runs before the specified actions, finding the join team request
  before_action :find_request, only: %i[show update destroy decline accept]

  # Centralized authorization method
  def action_allowed?
    case params[:action]
    when 'index'
      # Only administrators can view all join team requests
      current_user_has_admin_privileges?
    
    when 'create'
      # Any student can create a join team request
      current_user_has_student_privileges?
    
    when 'show'
      # The participant who made the request OR any team member can view it
      return false unless current_user_has_student_privileges?
      # Load the request for authorization check
      @join_team_request = JoinTeamRequest.find_by(id: params[:id]) unless @join_team_request
      return false unless @join_team_request
      current_user_is_request_creator? || current_user_is_team_member?
    
    when 'update', 'destroy'
      # Only the participant who created the request can update or delete it
      return false unless current_user_has_student_privileges?
      # Load the request for authorization check
      @join_team_request = JoinTeamRequest.find_by(id: params[:id]) unless @join_team_request
      return false unless @join_team_request
      current_user_is_request_creator?
    
    when 'decline', 'accept'
      # Only team members of the target team can accept/decline a request
      return false unless current_user_has_student_privileges?
      # Load the request for authorization check
      @join_team_request = JoinTeamRequest.find_by(id: params[:id]) unless @join_team_request
      return false unless @join_team_request
      current_user_is_team_member?
    
    when 'for_team', 'by_user', 'pending'
      # Students can view filtered lists
      current_user_has_student_privileges?
    
    else
      # Default: deny access
      false
    end
  end

  # GET api/v1/join_team_requests
  # gets a list of all the join team requests
  def index
    join_team_requests = JoinTeamRequest.includes(:participant, :team).all
    render json: join_team_requests, each_serializer: JoinTeamRequestSerializer, status: :ok
  end

  # GET api/v1/join_team_requests/1
  # show the join team request that is passed into the route
  def show
    render json: @join_team_request, serializer: JoinTeamRequestSerializer, status: :ok
  end

  # GET api/v1/join_team_requests/for_team/:team_id
  # Get all join team requests for a specific team
  def for_team
    team = Team.find(params[:team_id])
    join_team_requests = team.join_team_requests.includes(:participant, :team)
    render json: join_team_requests, each_serializer: JoinTeamRequestSerializer, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Team not found' }, status: :not_found
  end

  # GET api/v1/join_team_requests/by_user/:user_id
  # Get all join team requests created by a specific user
  def by_user
    participant_ids = Participant.where(user_id: params[:user_id]).pluck(:id)
    join_team_requests = JoinTeamRequest.where(participant_id: participant_ids).includes(:participant, :team)
    render json: join_team_requests, each_serializer: JoinTeamRequestSerializer, status: :ok
  end

  # GET api/v1/join_team_requests/pending
  # Get all pending join team requests
  def pending
    join_team_requests = JoinTeamRequest.where(reply_status: PENDING).includes(:participant, :team)
    render json: join_team_requests, each_serializer: JoinTeamRequestSerializer, status: :ok
  end

  # POST api/v1/join_team_requests
  # Creates a new join team request
  def create
    # Find participant based on assignment_id
    participant = AssignmentParticipant.find_by(user_id: @current_user.id, parent_id: params[:assignment_id])
    
    unless participant
      return render json: { error: 'You are not a participant in this assignment' }, status: :unprocessable_entity
    end

    team = Team.find_by(id: params[:team_id])
    unless team
      return render json: { error: 'Team not found' }, status: :not_found
    end

    # Check if user already belongs to the team
    if team.participants.include?(participant)
      return render json: { error: 'You already belong to this team' }, status: :unprocessable_entity
    end

    # Check for duplicate pending requests
    existing_request = JoinTeamRequest.find_by(
      participant_id: participant.id,
      team_id: team.id,
      reply_status: PENDING
    )
    
    if existing_request
      return render json: { error: 'You already have a pending request for this team' }, status: :unprocessable_entity
    end

    # Create the request
    join_team_request = JoinTeamRequest.new(
      participant_id: participant.id,
      team_id: team.id,
      comments: params[:comments],
      reply_status: PENDING
    )

    if join_team_request.save
      render json: join_team_request, serializer: JoinTeamRequestSerializer, status: :created
    else
      render json: { errors: join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # PATCH/PUT api/v1/join_team_requests/1
  # Updates a join team request (comments only, not status)
  def update
    # Only allow updating comments
    if @join_team_request.update(comments: params[:comments])
      render json: @join_team_request, serializer: JoinTeamRequestSerializer, status: :ok
    else
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE api/v1/join_team_requests/1
  # delete a join team request
  def destroy
    if @join_team_request.destroy
      render json: { message: 'Join team request was successfully deleted' }, status: :ok
    else
      render json: { error: 'Failed to delete join team request' }, status: :unprocessable_entity
    end
  end

  # PATCH api/v1/join_team_requests/1/accept
  # Accept a join team request and add the participant to the team
  def accept
    # Check if request is still pending
    unless @join_team_request.reply_status == PENDING
      return render json: { error: 'This request has already been processed' }, status: :unprocessable_entity
    end

    # Check if team is full
    team = @join_team_request.team
    if team.full?
      return render json: { error: 'Team is full' }, status: :unprocessable_entity
    end

    participant = @join_team_request.participant

    # Use a transaction to ensure both removal and addition happen atomically
    ActiveRecord::Base.transaction do
      # Find and remove participant from their old team (if any)
      old_team_participant = TeamsParticipant.find_by(participant_id: participant.id)
      if old_team_participant
        old_team = old_team_participant.team
        old_team_participant.destroy!
        
        # If the old team is now empty, optionally clean up (but keep the team for now)
        Rails.logger.info "Removed participant #{participant.id} from old team #{old_team&.id}"
      end

      # Add participant to the new team
      team_participant = TeamsParticipant.create!(
        participant_id: participant.id,
        team_id: team.id,
        user_id: participant.user_id
      )

      # Update the request status
      @join_team_request.reply_status = ACCEPTED
      @join_team_request.save!

      render json: { 
        message: 'Join team request accepted successfully', 
        join_team_request: JoinTeamRequestSerializer.new(@join_team_request).as_json
      }, status: :ok
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH api/v1/join_team_requests/1/decline
  # Decline a join team request
  def decline
    # Check if request is still pending
    unless @join_team_request.reply_status == PENDING
      return render json: { error: 'This request has already been processed' }, status: :unprocessable_entity
    end

    @join_team_request.reply_status = DECLINED
    if @join_team_request.save
      render json: { 
        message: 'Join team request declined successfully',
        join_team_request: JoinTeamRequestSerializer.new(@join_team_request).as_json
      }, status: :ok
    else
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  
  # checks if the team is full already
  def check_team_status
    team = Team.find(params[:team_id])
    if team.full?
      render json: { message: 'This team is full.' }, status: :unprocessable_entity
    end
  end

  # Finds the join team request by ID
  def find_request
    @join_team_request = JoinTeamRequest.find(params[:id])
  end

  # Permits specified parameters for join team requests
  def join_team_request_params
    params.require(:join_team_request).permit(:comments, :reply_status)
  end

  # Helper method to check if current user is the creator of the request
  def current_user_is_request_creator?
    return false unless @join_team_request && @current_user
    
    participant = Participant.find_by(id: @join_team_request.participant_id)
    participant&.user_id == @current_user.id
  end

  # Helper method to check if current user is a member of the target team
  def current_user_is_team_member?
    return false unless @join_team_request && @current_user
    
    team = Team.find_by(id: @join_team_request.team_id)
    return false unless team
    
    # Find the participant record for the current user in the same assignment
    # We need to get the assignment from the team
    if team.is_a?(AssignmentTeam)
      participant = AssignmentParticipant.find_by(
        user_id: @current_user.id,
        parent_id: team.parent_id
      )
      return false unless participant
      
      team.participants.include?(participant)
    else
      false
    end
  end
end