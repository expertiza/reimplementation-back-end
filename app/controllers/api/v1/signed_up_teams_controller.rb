class Api::V1::SignedUpTeamsController < ApplicationController

  def index
    @sign_up_topic = SignUpTopic.find(params[:topic_id])
    @signed_up_team = SignedUpTeam.find_team_participants(@sign_up_topic.assignment_id)
    render json: @signed_up_team
  end
  def create(topic_id, team_id)
    @sign_up_topic = SignUpTopic.where(assignment_id: topic_id).first
    @signed_up_team = SignedUpTeam.new()
    @signed_up_team.topic_id = @sign_up_topic.id
    @signed_up_team.team_id = team_id
    if @signed_up_team.save
      render json: {message: "Signed up team successful!"}, status: :created
    else
      render json: {message: @signed_up_team.errors}, status: :unprocessable_entity
    end
  end

  def update
    @signed_up_team = SignedUpTeam.find(params[:id])
    if @signed_up_team.update(signed_up_teams_params)
      render json: {message: "The team has been updated successfully. "}, status: 200
    else
      render json: @signed_up_team.errors, status: :unprocessable_entity
    end
  end

  def sign_up
    team_id = params[:team_id]
    topic_id = params[:topic_id]
    create(topic_id, team_id)
  end

  #Method for signing up as student
  def sign_up_student
    user_id = params[:user_id]
    topic_id = params[:topic_id]
    team_id = TeamUser.find(user_id: user_id)
    create(topic_id, team_id)
  end

  def destroy
    @signed_up_team = SignedUpTeam.find(params[:id])
    if @signed_up_team.drop_team
      render json: {message: 'Signed up teams was deleted successfully!'}, status: 200
    else
      render json: @signed_up_team.errors, status: :unprocessable_entity
    end
  end


  private
  def signed_up_teams_params
    params.require(:signed_up_team).permit(:topic_id, :team_id, :is_waitlisted, :preference_priority_number)
  end

end
