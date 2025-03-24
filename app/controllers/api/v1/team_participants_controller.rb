class TeamsParticipantsController < ApplicationController
  include AuthorizationHelper

  # Update duties only if student privileges are present
  def action_allowed?
    return current_user_has_student_privileges? if params[:action] == "update_duties"

    current_user_has_ta_privileges?
  end

  # Auto completing username when adding a new member to a team
  def auto_complete_for_user_name
    team = Team.find(session[:team_id])
    
    # Finds possible team members based on partial names
    @users = team.possible_team_members(params[:user][:name])
    render inline: "<%= auto_complete_result @users, 'name' %>", layout: false
  end

  # Updating the duties assigned to a team member
  def update_duties
    team_participant = TeamsParticipant.find(params[:teams_participant_id])
    team_participant.update(duty_id: params[:teams_participant]['duty_id'])
    redirect_to controller: 'student_teams', action: 'view', student_id: params[:participant_id]
  end

  # Listing all participants of a team
  def list
    @team = Team.find(params[:id])
    @assignment = Assignment.find(@team.parent_id)
    @teams_participants = TeamsParticipant.where(team_id: params[:id]).page(params[:page]).per(10)
  end

  # Finding a team by the team id
  def new
    @team = Team.find(params[:id])
  end

  # Adding a participant to a team
  def create
    user = User.find_by(name: params[:user][:name].strip)
    # Throwing an error if no user is found
    if user.nil?
      flash[:error] = user_not_found_message(params[:user][:name])
      redirect_back fallback_location: root_path
      return
    end

    team = Team.find(params[:id])
    assignment_or_course = team.parent

    # Checking if a participant is valid for the assigned team or course
    unless valid_participant?(user, assignment_or_course)
      redirect_back fallback_location: root_path
      return
    end

    # Adding a member to a team and then checking if there are any errors to that
    begin
      add_member_return = team.add_member(user, team.parent_id)
      flash[:error] = "This team already has the maximum number of members." if add_member_return == false
      undo_link("The participant \"#{user.name}\" has been successfully added to \"#{team.name}\".") if add_member_return
    rescue
      flash[:error] = "The user #{user.name} is already a member of the team #{team.name}"
    end

    redirect_to controller: 'teams', action: 'list', id: team.parent_id
  end

  # Removing a participant from a team
  def delete
    team_participant = TeamsParticipant.find(params[:id])
    parent_id = Team.find(team_participant.team_id).parent_id
    user = User.find(team_participant.participant.user_id)
    team_participant.destroy

    undo_link("The participant \"#{user.name}\" has been successfully removed.")
    redirect_to controller: 'teams', action: 'list', id: parent_id
  end

  # Deleting multiple participants from a team
  def delete_selected
    TeamsParticipant.where(id: params[:item]).destroy_all
    redirect_to action: 'list', id: params[:id]
  end

  private
  def user_not_found_message(user_name)
    urlCreate = url_for controller: 'users', action: 'new'
    "\"#{user_name.strip}\" is not defined. Please <a href=\"#{urlCreate}\">create</a> this user before continuing."
  end

  # Checking if a participant is already assigned to a team
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

  # Returning an error when a participant is not found
  def participant_not_found_message(user_name, assignment_or_course)
    urlParticipantList = url_for controller: 'participants', action: 'list', id: assignment_or_course.id, model: assignment_or_course.class.name, authorization: 'participant'
    "\"#{user_name}\" is not a participant of the current #{assignment_or_course.class.name.downcase}. Please <a href=\"#{urlParticipantList}\">add</a> this user before continuing."
  end
end
