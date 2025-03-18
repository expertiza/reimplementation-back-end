class TeamsParticipantsController < ApplicationController
  include AuthorizationHelper

  def action_allowed?
    return current_user_has_student_privileges? if params[:action] == "update_duties"

    current_user_has_ta_privileges?
  end

  def auto_complete_for_user_name
    team = Team.find(session[:team_id])
    @users = team.possible_team_members(params[:user][:name])
    render inline: "<%= auto_complete_result @users, 'name' %>", layout: false
  end

  def update_duties
    team_participant = TeamsParticipant.find(params[:teams_participant_id])
    team_participant.update(duty_id: params[:teams_participant]['duty_id'])
    redirect_to controller: 'student_teams', action: 'view', student_id: params[:participant_id]
  end

  def list
    @team = Team.find(params[:id])
    @assignment = Assignment.find(@team.parent_id)
    @teams_participants = TeamsParticipant.where(team_id: params[:id]).page(params[:page]).per(10)
  end

  def new
    @team = Team.find(params[:id])
  end

  def create
    user = User.find_by(name: params[:user][:name].strip)
    if user.nil?
      flash[:error] = user_not_found_message(params[:user][:name])
      redirect_back fallback_location: root_path
      return
    end

    team = Team.find(params[:id])
    assignment_or_course = team.parent

    unless valid_participant?(user, assignment_or_course)
      redirect_back fallback_location: root_path
      return
    end

    begin
      add_member_return = team.add_member(user, team.parent_id)
      flash[:error] = "This team already has the maximum number of members." if add_member_return == false
      undo_link("The participant \"#{user.name}\" has been successfully added to \"#{team.name}\".") if add_member_return
    rescue
      flash[:error] = "The user #{user.name} is already a member of the team #{team.name}"
    end

    redirect_to controller: 'teams', action: 'list', id: team.parent_id
  end

  def delete
    team_participant = TeamsParticipant.find(params[:id])
    parent_id = Team.find(team_participant.team_id).parent_id
    user = User.find(team_participant.participant.user_id)
    team_participant.destroy

    undo_link("The participant \"#{user.name}\" has been successfully removed.")
    redirect_to controller: 'teams', action: 'list', id: parent_id
  end

  def delete_selected
    TeamsParticipant.where(id: params[:item]).destroy_all
    redirect_to action: 'list', id: params[:id]
  end

  private

  def user_not_found_message(user_name)
    urlCreate = url_for controller: 'users', action: 'new'
    "\"#{user_name.strip}\" is not defined. Please <a href=\"#{urlCreate}\">create</a> this user before continuing."
  end

  def valid_participant?(user, assignment_or_course)
    if assignment_or_course.user_on_team?(user)
      flash[:error] = "This user is already assigned to a team for this #{assignment_or_course.class.name.downcase}."
      return false
    end

    participant = assignment_or_course.participants.find_by(user_id: user.id)
    unless participant
      flash[:error] = participant_not_found_message(user.name, assignment_or_course)
      return false
    end

    true
  end

  def participant_not_found_message(user_name, assignment_or_course)
    urlParticipantList = url_for controller: 'participants', action: 'list', id: assignment_or_course.id, model: assignment_or_course.class.name, authorization: 'participant'
    "\"#{user_name}\" is not a participant of the current #{assignment_or_course.class.name.downcase}. Please <a href=\"#{urlParticipantList}\">add</a> this user before continuing."
  end
end