class SignedUpTeamsController < ApplicationController

  # Returns signed up topics using sign_up_topic assignment id
  def index
    result = SignedUpTeam.get_team_participants_for_topic(params[:topic_id])
    
    if result[:success]
      render json: result[:participants], status: :ok
    else
      render json: { message: result[:message] }, status: :not_found
    end
  end

  # Implemented by signed_up_team.rb (Model) --> create_signed_up_team
  def create; end

  # Update signed_up_team using parameters.
  def update
    result = SignedUpTeam.update_signed_up_team(params[:id], signed_up_teams_params)
    
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  # Sign up using parameters: team_id and topic_id
  def sign_up
    result = SignedUpTeam.sign_up_team_for_topic(params[:team_id], params[:topic_id])
    
    if result[:success]
      render json: result.except(:success), status: :created
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  # Method for signing up as student
  def sign_up_student
    result = SignedUpTeam.sign_up_student_for_topic(params[:user_id], params[:topic_id])
    
    if result[:success]
      render json: result.except(:success), status: :created
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  # Delete signed_up team
  def destroy
    @signed_up_team = SignedUpTeam.find(params[:id])
    if SignedUpTeam.delete_signed_up_team(@signed_up_team.team_id)
      render json: { message: 'Signed up teams was deleted successfully!' }, status: :ok
    else
      render json: { message: 'Failed to delete signed up team' }, status: :unprocessable_entity
    end
  end

  # Drop a topic for a student
  def drop_topic
    result = SignedUpTeam.drop_topic_for_student(params[:user_id], params[:topic_id])
    
    if result[:success]
      render json: result.except(:success), status: :ok
    else
      status = result[:message].include?("not found") ? :not_found : :unprocessable_entity
      render json: { message: result[:message] }, status: status
    end
  end

  # Drop a team from a topic (admin function)
  def drop_team_from_topic
    result = SignedUpTeam.drop_team_from_topic_by_admin(params[:topic_id], params[:team_id])
    
    if result[:success]
      render json: result.except(:success), status: :ok
    else
      status = result[:message].include?("not found") ? :not_found : :unprocessable_entity
      render json: { message: result[:message] }, status: status
    end
  end

  private

  def signed_up_teams_params
    params.require(:signed_up_team).permit(:topic_id, :team_id, :is_waitlisted, :preference_priority_number)
  end

end
