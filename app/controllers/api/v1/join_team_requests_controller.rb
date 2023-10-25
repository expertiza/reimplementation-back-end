class Api::V1::JoinTeamRequestsController < ApplicationController
  # Constants used to indicate status for the request
  # The datatype for status is string
  PENDING = 'P'
  DECLINED = 'D'
  ACCEPTED = 'A'


  # TODO Once the check_team_status is implemented below, uncomment this line
  # before_action :check_team_status, only: [:create]
  before_action :find_request, only: %i[show update destroy decline]

  def action_allowed?
    @current_user.student?
  end

  # GET api/v1/join_team_requests
  def index
    unless @current_user.administrator?
      render json: { errors: 'Unauthorized' }, status: :unauthorized
    end
    @join_team_requests = JoinTeamRequest.all
    render json: @join_team_requests
  end


  # GET api/v1join_team_requests/1
  def show
    render json: @join_team_request
  end

  # POST api/v1/join_team_requests
  def create

    @join_team_request = JoinTeamRequest.new
    @join_team_request.comments = params[:comments]
    @join_team_request.status = PENDING
    @join_team_request.team_id = params[:team_id]


    participant = Participant.where(user_id: @current_user.id, assignment_id: params[:assignment_id]).first

    # TODO Uncomment this code once team model and controller is implemented such that teams have participants
    # team = Team.find(params[:team_id])
    # if team.participants.include?(participant)
    #   render json: { error: 'You already belong to the team' }, status: :unprocessable_entity
    # else
    if participant
      @join_team_request.participant_id = participant.id
      if @join_team_request.save
        render json: @join_team_request, status: :created
      else
        render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: "Participant not found" }, status: :unprocessable_entity
    end

    # end
  end

  # PATCH/PUT api/v1/join_team_requests/1
  def update
    if @join_team_request.update(join_team_request_params)
      render json: { message: 'JoinTeamRequest was successfully updated' }, status: :ok
    else
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE api/v1/join_team_requests/1
  def destroy
     @join_team_request.destroy
  end

  def decline
    @join_team_request.status = DECLINED

    if @join_team_request.save
      render json: { message: 'JoinTeamRequest declined successfully' }, status: :ok
    else
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def accept
    @join_team_request.status = ACCEPTED

    if @join_team_request.save
      render json: { message: 'JoinTeamRequest accepted successfully' }, status: :ok
    else
      render json: { errors: @join_team_request.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # TODO Uncomment and modify this code as necessary when TeamUser controller and Teams model is complete
  # def check_team_status
  #
  #   team_member = TeamsUser.where(['team_id = ? and user_id = ?', params[:team_id], session[:user][:id]])
  #   team = Team.find(params[:team_id])
  #
  #   if team.full?
  #     render json: { message: 'This team is full.' }, status: :unprocessable_entity
  #   elsif team_member.any?
  #     render json: { message: 'You are already a member of this team.' }, status: :unprocessable_entity
  #   else
  #     render json: { message: 'Team is available for joining.' }, status: :ok
  #   end
  # end

  def find_request
    @join_team_request = JoinTeamRequest.find(params[:id])
    # render json: @join_team_request
  end


  def join_team_request_params
    # params.require(:join_team_request).permit(:comments, :status)
    params.require(:join_team_request).permit(:comments)

  end
end
