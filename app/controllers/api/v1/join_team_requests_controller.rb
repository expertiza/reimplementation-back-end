class Api::V1::JoinTeamRequestsController < ApplicationController
  # Constants used to indicate status for the request
  PENDING = 'PENDING'
  DECLINED = 'DECLINED'
  ACCEPTED = 'ACCEPTED'

  # This filter runs before the create action, checking if the team is full
  before_action :check_team_status, only: [:create]

  # This filter runs before the specified actions, finding the join team request
  before_action :find_request, only: %i[show update destroy decline]

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
    
    when 'decline'
      # Only team members of the target team can decline a request
      return false unless current_user_has_student_privileges?
      # Load the request for authorization check
      @join_team_request = JoinTeamRequest.find_by(id: params[:id]) unless @join_team_request
      return false unless @join_team_request
      current_user_is_team_member?
    
    else
      # Default: deny access
      false
    end
  end

  # GET api/v1/join_team_requests
  # gets a list of all the join team requests
  def index
    join_team_requests = JoinTeamRequest.all
    render json: join_team_requests, status: :ok
  end

  # GET api/v1join_team_requests/1
  # show the join team request that is passed into the route
  def show
    render json: @join_team_request, status: :ok
  end

  # POST api/v1/join_team_requests
  # Creates a new join team request
  def create
    join_team_request = JoinTeamRequest.new
    join_team_request.comments = params[:comments]
    join_team_request.reply_status = PENDING
    join_team_request.team_id = params[:team_id]
    
    # Find participant based on assignment_id
    participant = AssignmentParticipant.find_by(user_id: @current_user.id, parent_id: params[:assignment_id])
    team = Team.find(params[:team_id])

    if team.participants.include?(participant)
      render json: { error: 'You already belong to the team' }, status: :unprocessable_entity
    elsif participant
      join_team_request.participant_id = participant.id
      if join_team_request.save
        render json: join_team_request, status: :created
      else
        render json: { errors: join_team_request.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: 'Participant not found' }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT api/v1/join_team_requests/1
  # Updates a join team request
  def update
    if @join_team_request.update(join_team_request_params)
      render json: { message: 'JoinTeamRequest was successfully updated' }, status: :ok
    else
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE api/v1/join_team_requests/1
  # delete a join team request
  def destroy
    if @join_team_request.destroy
      render json: { message: 'JoinTeamRequest was successfully deleted' }, status: :ok
    else
      render json: { errors: 'Failed to delete JoinTeamRequest' }, status: :unprocessable_entity
    end
  end

  # decline a join team request
  def decline
    @join_team_request.reply_status = DECLINED
    if @join_team_request.save
      render json: { message: 'JoinTeamRequest declined successfully' }, status: :ok
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
