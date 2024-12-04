class Api::V1::TeamsParticipantsController < ApplicationController
  include AuthorizationHelper

  # Determines if the current user is allowed to perform the requested action.
  def action_allowed?
    if %w[update_duties].include? params[:action]
      current_user_has_student_privileges?
    else
      current_user_has_ta_privileges?
    end
  end

  # Fetches and renders an auto-complete list of possible team members based on a partial name input.
  def auto_complete_for_participant_name
    # Fetch the current team using the session-stored `team_id`.
    current_team = Team.find(session[:team_id])

    # Fetch potential members for the team based on the input name.
    @potential_team_members = current_team.get_possible_team_members(params[:user][:name])

    # Render the autocomplete suggestions.
    render inline: "<%= auto_complete_result @potential_team_members, 'name' %>", layout: false
  end

  # Updates the duty (role) assigned to a participant in a team.
  def update_duties
    # Find the team member relationship using the provided ID.
    team_member_relationship = TeamsUser.find(params[:teams_user_id])

    # Update the duty of the team member.
    team_member_relationship.update_attribute(:duty_id, params[:teams_user]['duty_id'])

    # Redirect to the participant's team view page.
    redirect_to controller: 'student_teams', action: 'view', student_id: params[:participant_id]
  end

  # Displays a paginated list of all participants in a specific team.
  def list_participants
    # Fetch the team based on the provided ID.
    current_team = Team.find(params[:id])

    # Retrieve the associated assignment or course for the team.
    associated_assignment_or_course = Assignment.find(current_team.parent_id)

    # Query and paginate participants of the current team.
    @team_participants = TeamsUser.page(params[:page]).per_page(10).where(team_id: current_team.id)

    @team = current_team
    @assignment = associated_assignment_or_course
  end

  # Renders the form for adding a new participant to a team.
  def add_new_participant
    # Fetch the team for which a participant is to be added.
    @team = Team.find(params[:id])
  end

  # Adds a new participant to a team after validation.
  def create_participant
    # Find the user by their name from the input.
    find_participant = find_participant_by_name

    # Fetch the team using the provided ID.
    current_team = find_team_by_id

    if validate_participant_and_team(participant, team)
      if team.add_participants_with_handling(participant, team.parent_id)
        undo_link("The participant \"#{participant.name}\" has been successfully added to \"#{team.name}\".")
      else
        flash[:error] = 'This team already has the maximum number of members.'
      end
    end

    # Redirect to the list of teams for the parent assignment or course.
    redirect_to controller: 'teams', action: 'list', id: current_team.parent_id
  end

  #Deletes the selected participant
  def delete_selected_participant
    @teams_user = TeamsUser.find(params[:id])
    parent_id = Team.find(@teams_user.team_id).parent_id
    @user = User.find(@teams_user.user_id)
    @teams_user.destroy
    undo_link("The team user \"#{@user.name}\" has been successfully removed. ")
    redirect_to controller: 'teams', action: 'list', id: parent_id
  end
  
  private

  # Helper method to find a user by their name.
  def find_participant_by_name
    # Locate the user by their name.
    find_participant = User.find_by(name: params[:user][:name].strip)

    # Display an error if the user is not found.
    unless find_participant
      flash[:error] = participant_not_found_error
      redirect_back fallback_location: root_path
    end
    participant
  end

  # Helper method to fetch a team by its ID.
  def find_team_by_id
    Team.find(params[:id])
  end

  # Validates whether a participant can be added to the given team.
  def validate_participant_and_team(participant, team)
    # Check if the participant is valid for the team type.
    validation_result = if team.is_a?(AssignmentTeam)
                          Assignment.find(team.parent_id).valid_team_participant?(participant)
                        else
                          Course.find(team.parent_id).valid_team_participant?(participant)
                        end

    # Handle validation errors if any.
    if validation_result[:success]
      true
    else
      flash[:error] = validation_result[:error]
      redirect_back fallback_location: root_path
      false
    end
  end

  # Adds the participant to the team while handling constraints.
  def add_participant_to_team(find_participant, team)
    # Add the participant to the team and handle the outcome.
    addition_result = find_team_by_id.add_participant(find_participant, team.parent_id)
    handle_addition_result(find_participant, team, addition_result)
  end

  # Handles the result of adding a participant to the team.
  def handle_addition_result(find_participant, team, addition_result)
    if addition_result == false
      flash[:error] = 'This team already has the maximum number of members.'
    else
      undo_link("The team user \"#{find_participant.name}\" has been successfully added to \"#{team.name}\".")
    end
  end

  # Generates an error message when a user is not found.
  def participant_not_found_error
    new_participnat_url = url_for controller: 'users', action: 'new'
    "\"#{params[:user][:name].strip}\" is not defined. Please <a href=\"#{new_participant_url}\">create</a> this user before continuing."
  end

  def non_participant_error(find_participant, parent_id, model)
    urlParticipantList = url_for controller: 'participants', action: 'list', id: parent_id, model: model, authorization: 'participant'
    "\"#{find_participant.name}\" is not a participant of the current course/assignment. Please <a href=\"#{urlParticipantList}\">add</a> this user before continuing."
  end
end
