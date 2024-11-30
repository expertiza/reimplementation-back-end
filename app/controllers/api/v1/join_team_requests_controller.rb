class Api::V1::JoinTeamRequestsController < ApplicationController
  # Constants used to indicate status for the request
  PENDING = 'PENDING'
  DECLINED = 'DECLINED'
  ACCEPTED = 'ACCEPTED'

  # This filter runs before the create action, checking if the team is full
  before_action :check_team_status, only: [:create]

  # This filter runs before the specified actions, finding the join team request
  before_action :find_request, only: %i[show update destroy decline]

  #checks if the current user is a student
  def action_allowed?
    @current_user.student?
  end

  # GET api/v1/join_team_requests
  # gets a list of all the join team requests
  def index
    unless @current_user.administrator?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Unauthorized access to join team requests.", request)
      return render json: { errors: 'Unauthorized' }, status: :unauthorized
    end
    join_team_requests = JoinTeamRequest.all
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched all join team requests.", request)
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
    join_team_request.status = PENDING
    join_team_request.team_id = params[:team_id]
    participant = Participant.where(user_id: @current_user.id, assignment_id: params[:assignment_id]).first
    team = Team.find(params[:team_id])

    if team.participants.include?(participant)
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "User already belongs to team ID: #{team.id}.", request)
      render json: { error: 'You already belong to the team' }, status: :unprocessable_entity
    elsif participant
      join_team_request.participant_id = participant.id
      if join_team_request.save
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Created join team request with ID: #{join_team_request.id}.", request)
        render json: join_team_request, status: :created
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to create join team request. Errors: #{join_team_request.errors.full_messages.join(', ')}", request)
        render json: { errors: join_team_request.errors.full_messages }, status: :unprocessable_entity
      end
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Participant not found for user ID: #{@current_user.id}.", request)
      render json: { errors: 'Participant not found' }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT api/v1/join_team_requests/1
  # Updates a join team request
  def update
    if @join_team_request.update(join_team_request_params)
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Updated join team request with ID: #{@join_team_request.id}.", request)
      render json: { message: 'JoinTeamRequest was successfully updated' }, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to update join team request with ID: #{@join_team_request.id}. Errors: #{@join_team_request.errors.full_messages.join(', ')}", request)
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE api/v1/join_team_requests/1
  # delete a join team request
  def destroy
    if @join_team_request.destroy
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Deleted join team request with ID: #{@join_team_request.id}.", request)
      render json: { message: 'JoinTeamRequest was successfully deleted' }, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to delete join team request with ID: #{@join_team_request.id}.", request)
      render json: { errors: 'Failed to delete JoinTeamRequest' }, status: :unprocessable_entity
    end
  end

  # decline a join team request
  def decline
    @join_team_request.status = DECLINED
    if @join_team_request.save
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Declined join team request with ID: #{@join_team_request.id}.", request)
      render json: { message: 'JoinTeamRequest declined successfully' }, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to decline join team request with ID: #{@join_team_request.id}. Errors: #{@join_team_request.errors.full_messages.join(', ')}", request)
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  # checks if the team is full already
  def check_team_status
    team = Team.find(params[:team_id])
    if team.full?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Attempted to join a full team with ID: #{team.id}.", request)
      render json: { message: 'This team is full.' }, status: :unprocessable_entity
    end
  end

  # Finds the join team request by ID
  def find_request
    @join_team_request = JoinTeamRequest.find(params[:id])
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Found join team request with ID: #{@join_team_request.id}.", request)
  end

  # Permits specified parameters for join team requests
  def join_team_request_params
    params.require(:join_team_request).permit(:comments, :status)
  end
end
