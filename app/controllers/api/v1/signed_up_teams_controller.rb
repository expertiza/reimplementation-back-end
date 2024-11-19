class Api::V1::SignedUpTeamsController < ApplicationController

  # Returns signed up topics using sign_up_topic assignment id
  # Retrieves sign_up_topic using topic_id as a parameter
  def index
    # puts params[:topic_id]
    @sign_up_topic = SignUpTopic.find(params[:topic_id])
    @signed_up_team = SignedUpTeam.find_team_participants(@sign_up_topic.assignment_id)
    render json: @signed_up_team
  end

  # Implemented by signed_up_team.rb (Model) --> create_signed_up_team
  def create; end

  # Update signed_up_team using parameters.
  def update
    @signed_up_team = SignedUpTeam.find(params[:id])
    if @signed_up_team.update(signed_up_teams_params)
      render json: { message: "The team has been updated successfully. " }, status: 200
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, $ERROR_INFO, request)
      render json: @signed_up_team.errors, status: :unprocessable_entity
    end
  end

  # Sign up using parameters: team_id and topic_id
  # Calls model method create_signed_up_team
  def sign_up
    team_id = params[:team_id]
    topic_id = params[:topic_id]
    @signed_up_team = SignedUpTeam.create_signed_up_team(topic_id, team_id)
    if @signed_up_team
      render json: { message: "Signed up team successful!" }, status: :created
    else
      render json: { message: @signed_up_team.errors }, status: :unprocessable_entity
    end
  end

  # Method for signing up as student
  # Params : topic_id
  # Get team_id using model method get_team_participants
  # Call create_signed_up_team Model method
  def sign_up_student
    user_id = params[:user_id]
    topic_id = params[:topic_id]
    team_id = SignedUpTeam.get_team_participants(user_id)
    # @teams_user = TeamsUser.where(user_id: user_id).first
    # team_id = @teams_user.team_id
    @signed_up_team = SignedUpTeam.create_signed_up_team(topic_id, team_id)
    # create(topic_id, team_id)
    if @signed_up_team
      render json: { message: "Signed up team successful!" }, status: :created
    else
      render json: { message: @signed_up_team.errors }, status: :unprocessable_entity
    end
  end

  # Delete signed_up team. Calls method delete_signed_up_team from the model.
  def destroy
    @signed_up_team = SignedUpTeam.find(params[:id])
    if SignedUpTeam.delete_signed_up_team(@signed_up_team.team_id)
      render json: { message: 'Signed up teams was deleted successfully!' }, status: :ok
    else
      render json: @signed_up_team.errors, status: :unprocessable_entity
    end
  end

  private

  def signed_up_teams_params
    params.require(:signed_up_team).permit(:topic_id, :team_id, :is_waitlisted, :preference_priority_number)
  end

end
