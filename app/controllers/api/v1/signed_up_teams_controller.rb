class Api::V1::SignedUpTeamsController < ApplicationController

  # Returns signed up teams
  # Can query by topic_id or assignment_id
  def index
    if params[:assignment_id].present?
      # Get all signed up teams for an assignment (across all topics)
      topic_ids = SignUpTopic.where(assignment_id: params[:assignment_id]).pluck(:id)
      @signed_up_teams = SignedUpTeam.where(sign_up_topic_id: topic_ids)
                                      .includes(team: :users, sign_up_topic: :assignment)
      render json: @signed_up_teams, include: { team: { methods: [:team_size, :max_size] }, sign_up_topic: {} }
    elsif params[:topic_id].present?
      # Get signed up teams for a specific topic with their participants
      @signed_up_teams = SignedUpTeam.where(sign_up_topic_id: params[:topic_id])
                                      .includes(team: :users, sign_up_topic: :assignment)
      render json: @signed_up_teams, include: { team: { include: :users, methods: [:team_size, :max_size] }, sign_up_topic: {} }
    else
      render json: { error: 'Either assignment_id or topic_id parameter is required' }, status: :bad_request
    end
  end

  def show
    @signed_up_team = SignedUpTeam.find_by(id:params[:id])
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

  def create_advertisement
    params[:signed_up_team] = { advertise_for_partner: true, comments_for_advertisement: params[:comments_for_advertisement] }
    update_custom_message("Advertisement created successfully.")
  end

  def update_advertisement
    params[:signed_up_team] = { comments_for_advertisement: params[:comments_for_advertisement] }
    update_custom_message("Advertisement updated successfully.")
  end

  def remove_advertisement
    params[:signed_up_team] = { advertise_for_partner: false, comments_for_advertisement: nil }
    update_custom_message("Advertisement removed successfully.")
  end

  private

  def update_custom_message(message)
    @signed_up_team = SignedUpTeam.find(params[:id])
    if @signed_up_team.update(signed_up_teams_params)
      render json: { success: true, message: message }, status: :ok
    else
      render json: {message: @signed_up_team.errors.first, success:false}, status: :unprocessable_entity
    end
  end

  def signed_up_teams_params
    params.require(:signed_up_team).permit(:topic_id, :team_id, :is_waitlisted, :preference_priority_number, :comments_for_advertisement, :advertise_for_partner)
  end

end
