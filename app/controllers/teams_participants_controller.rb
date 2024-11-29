class TeamsUsersController < ApplicationController
  include AuthorizationHelper

  # Check permissions for actions
  def action_allowed?
    if %w[update_duties].include?(params[:action])
      current_user_has_student_privileges?
    else
      current_user_has_ta_privileges?
    end
  end

  # Autocomplete user names for adding members to a team
  def auto_complete_for_user_name
    team = Team.find_by(id: session[:team_id])
    if team
      @users = team.get_members.where("name LIKE ?", "%#{params[:user][:name]}%")
      render inline: "<%= auto_complete_result @users, 'name' %>", layout: false
    else
      render plain: "Team not found", status: :not_found
    end
  end

  # Add a user to a team
  def create
    user = User.find_by(name: params[:user][:name].strip)
    return redirect_with_error("User not found. Please create the user.") unless user

    team = Team.find(params[:team_id])
    begin
      team.add_member(user)
      flash[:success] = "User #{user.name} successfully added to the team."
    rescue StandardError => e
      flash[:error] = e.message
    end

    redirect_to action: 'list', id: team.assignment_id
  end

  # Remove a user from a team
  def delete
    team = Team.find(params[:team_id])
    user = User.find(params[:user_id])

    begin
      team.remove_member(user)
      flash[:success] = "User #{user.name} successfully removed from the team."
    rescue StandardError => e
      flash[:error] = e.message
    end

    redirect_to action: 'list', id: team.assignment_id
  end

  # List all members of a team
  def list
    @team = Team.find(params[:id])
    @assignment = @team.assignment
    @teams_users = @team.teams_users.page(params[:page]).per_page(10)
  end

  # Update a team user's duties
  def update_duties
    team_user = TeamsUser.find(params[:teams_user_id])
    if team_user
      team_user.update!(duty_id: params[:teams_user][:duty_id])
      redirect_to controller: 'student_teams', action: 'view', student_id: params[:participant_id]
    else
      flash[:error] = "Team member not found."
      redirect_back fallback_location: root_path
    end
  rescue StandardError => e
    flash[:error] = e.message
    redirect_back fallback_location: root_path
  end

  # Delete selected users from a team
  def delete_selected
    team = Team.find(params[:id])
    user_ids = params[:item]

    begin
      user_ids.each do |user_id|
        user = User.find(user_id)
        team.remove_member(user)
      end
      flash[:success] = "Selected users successfully removed from the team."
    rescue StandardError => e
      flash[:error] = e.message
    end

    redirect_to action: 'list', id: team.assignment_id
  end
end