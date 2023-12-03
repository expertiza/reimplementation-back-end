class TeamsUsersController < ApplicationController

  def index
    teams_users = TeamsUser.all
    render json: teams_users, status: :ok
  end
  def list
    team = Team.find(params[:id])
    teams_users = TeamsUser.where(['team_id = ?', params[:id]])
    render json: teams_users, status: :ok
  end

  def new
    @team = Team.find(params[:id])
  end

  def create
    user = User.find_by(name: params[:user][:name].strip)

    unless user
      flash[:error] = user_not_defined_flash_error
      redirect_to controller: 'users', action: 'new'
      return
    end

    team = Team.find(params[:id])

    return if user_already_assigned?(user, team)

    handle_course_team(user, team)
    redirect_to_team_list(team)
  end

  def delete
    @teams_user = TeamsUser.find(params[:id])
    parent_id = Team.find(@teams_user.team_id).parent_id
    @user = User.find(@teams_user.user_id)
    @teams_user.destroy
    undo_link("The team user \"#{@user.name}\" has been successfully removed. ")
    redirect_to controller: 'teams', action: 'list', id: parent_id
  end

  def delete_selected
    params[:item].each do |item_id|
      team_user = TeamsUser.find(item_id)
      team_user.destroy
    end
    redirect_to action: 'list', id: params[:id]
  end

  private

  def user_not_defined_flash_error
    url_create = url_for(controller: 'users', action: 'new')
    "\"#{params[:user][:name].strip}\" is not defined. Please <a href=\"#{url_create}\">create</a> this user before continuing."
  end

  def handle_course_team(user, team)
    course = Course.find(team.parent_id)
    return if course_team_checks_fail(user, team, course)

    add_member_return = team.add_member(user, team.parent_id)
    handle_add_member_result(add_member_return, user, team, course)
  end

  def course_team_checks_fail(user, team, course)
    return if user_already_assigned_to_course?(user, team, course)

    url_course_participant_list = url_for(controller: 'participants', action: 'list', id: course.id, model: 'Course', authorization: 'participant')
    flash[:error] = "\"#{user.name}\" is not a participant of the current course. Please <a href=\"#{url_course_participant_list}\">add</a> this user before continuing."
    true
  end

  def user_already_assigned_to_course?(user, team, course)
    if course.user_on_team?(user)
      flash[:error] = "This user is already assigned to a team for this course"
      redirect_back fallback_location: root_path
      true
    else
      false
    end
  end
end
