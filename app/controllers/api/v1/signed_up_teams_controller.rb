class Api::V1::SignedUpTeamsController < ApplicationController

  def create
    @signed_up_team = SignedUpTeam.new(signed_up_teams_params)
    if @signed_up_team.save
      render json: {message: "The team: has been sucessfully assigned the topic "}, status: :created
    else
      render json: {message: @signed_up_team.errors}, status: :unprocessable_entity
    end
  end

  def update
    if @signed_up_team.update(signed_up_teams_params)
      render json: {message: "The team has been updated successfully. "}, status: 200
    else
      render json: @sign_up_topic.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @signed_up_team = SignedUpTeam.find(params[:id])
    @signed_up_team.destroy
  end

  private
  def signed_up_teams_params
    params.require(:signed_up_team).permit(:topic_id, :team_id, :is_waitlisted, :preference_priority_number)
  end

end
