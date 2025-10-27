class SignedUpTeamsController < ApplicationController

  # Returns signed up topics using sign_up_topic assignment id
  # Retrieves sign_up_topic using topic_id as a parameter
  def index
    # puts params[:topic_id]
    @project_topic = ProjectTopic.find(params[:topic_id])
    @signed_up_team = SignedUpTeam.find_team_participants(@project_topic.assignment_id)
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
  # Params : topic_id, user_id
  # Get team_id using model method get_team_participants
  # Call create_signed_up_team Model method
  def sign_up_student
    user_id = params[:user_id]
    topic_id = params[:topic_id]
    team_id = SignedUpTeam.get_team_participants(user_id)
    
    unless team_id
      render json: { message: "User is not part of any team" }, status: :unprocessable_entity
      return
    end
    
    # First, drop any existing topic signup for this team
    existing_signups = SignedUpTeam.where(team_id: team_id)
    if existing_signups.exists?
      existing_signups.each do |signup|
        signup.project_topic.drop_team(signup.team)
      end
    end
    
    @signed_up_team = SignedUpTeam.create_signed_up_team(topic_id, team_id)
    if @signed_up_team
      render json: { 
        message: "Signed up team successful!", 
        signed_up_team: @signed_up_team,
        available_slots: @signed_up_team.project_topic.available_slots
      }, status: :created
    else
      render json: { message: "Failed to sign up for topic. Topic may be full or already signed up." }, status: :unprocessable_entity
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

  # Drop a topic for a student
  def drop_topic
    user_id = params[:user_id]
    topic_id = params[:topic_id]
    team_id = SignedUpTeam.get_team_participants(user_id)
    
    unless team_id
      render json: { message: "User is not part of any team" }, status: :unprocessable_entity
      return
    end

    project_topic = ProjectTopic.find_by(id: topic_id)
    team = Team.find_by(id: team_id)
    
    unless project_topic && team
      render json: { message: "Topic or team not found" }, status: :not_found
      return
    end

    signed_up_team = SignedUpTeam.find_by(project_topic: project_topic, team: team)
    unless signed_up_team
      render json: { message: "Team is not signed up for this topic" }, status: :unprocessable_entity
      return
    end

    # Drop the team from the topic
    project_topic.drop_team(team)
    
    render json: { 
      message: "Successfully dropped topic!", 
      available_slots: project_topic.available_slots
    }, status: :ok
  end

  # Drop a team from a topic (admin function)
  def drop_team_from_topic
    topic_id = params[:topic_id]
    team_id = params[:team_id]
    
    project_topic = ProjectTopic.find_by(id: topic_id)
    team = Team.find_by(id: team_id)
    
    unless project_topic && team
      render json: { message: "Topic or team not found" }, status: :not_found
      return
    end

    signed_up_team = SignedUpTeam.find_by(project_topic: project_topic, team: team)
    unless signed_up_team
      render json: { message: "Team is not signed up for this topic" }, status: :unprocessable_entity
      return
    end

    # Drop the team from the topic
    project_topic.drop_team(team)
    
    render json: { 
      message: "Successfully dropped team from topic!", 
      available_slots: project_topic.available_slots
    }, status: :ok
  end

  private

  def signed_up_teams_params
    params.require(:signed_up_team).permit(:topic_id, :team_id, :is_waitlisted, :preference_priority_number)
  end

end
