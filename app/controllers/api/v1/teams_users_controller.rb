class TeamsUsersController < ApplicationController
  include AuthorizationHelper
  include ParticipantsHelper
  autocomplete :user, :name

  #The name of the function can be updated.
  def action_allowed?
    current_user_has_student_privileges? if %w[update_duties].include? params[:action]
    current_user_has_ta_privileges?
  end

  #Recommend using it views for teams_controller instead of text_field_with_auto_complete
  def auto_complete_for_user_name
    team = Team.find(session[:team_id])
    @users = team.get_possible_team_members(params[:user][:name])
    render inline: "<%= auto_complete_result @users, 'name' %>", layout: false
  end

  def create
    user = User.find_by(name: params[:user][:name].strip)
    unless user
      flash[:error] = user_not_defined_flash_error
      redirect_to_new_user_page
      return
    end

    team = Team.find(params[:id])
    return if user_already_assigned?(user, team)

    if team.is_a?(AssignmentTeam)
      handle_assignment_team(user, team)
    elsif team.is_a?(CourseTeam)
      handle_course_team(user, team)
    end

    redirect_to_team_list(team)
  end

  private

  def user_not_defined_flash_error
    url_create = url_for(controller: 'users', action: 'new')
    "\"#{params[:user][:name].strip}\" is not defined. Please <a href=\"#{url_create}\">create</a> this user before continuing."
  end

  def redirect_to_new_user_page
    redirect_to controller: 'users', action: 'new'
  end

  def handle_assignment_team(user, team)
    assignment = Assignment.find(team.parent_id)
    return if assignment_team_checks_fail(user, team, assignment)

    add_member_return = team.add_member(user, team.parent_id)
    handle_add_member_result(add_member_return, user, team, assignment)
  end

  def handle_course_team(user, team)
    course = Course.find(team.parent_id)
    return if course_team_checks_fail(user, team, course)

    add_member_return = team.add_member(user, team.parent_id)
    handle_add_member_result(add_member_return, user, team, course)
  end

  def assignment_team_checks_fail(user, team, assignment)
    return if user_already_assigned_to_assignment?(user, team, assignment)
    return unless assignment_participant_missing?(user, assignment)

    url_assignment_participant_list = url_for(controller: 'participants', action: 'list', id: assignment.id, model: 'Assignment', authorization: 'participant')
    flash[:error] = "\"#{user.name}\" is not a participant of the current assignment. Please <a href=\"#{url_assignment_participant_list}\">add</a> this user before continuing."
    true
  end

  def user_already_assigned_to_assignment?(user, team, assignment)
    if assignment.user_on_team?(user)
      flash[:error] = "This user is already assigned to a team for this assignment"
      redirect_back fallback_location: root_path
      true
    else
      false
    end
  end

  def assignment_participant_missing?(user, assignment)
    if AssignmentParticipant.find_by(user_id: user.id, parent_id: assignment.id).nil?
      true
    else
      false
    end
  end

  def course_team_checks_fail(user, team, course)
    return if user_already_assigned_to_course?(user, team, course)
    return unless course_participant_missing?(user, course)

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

  def course_participant_missing?(user, course)
    if CourseParticipant.find_by(user_id: user.id, parent_id: course.id).nil?
      true
    else
      false
    end
  end

end