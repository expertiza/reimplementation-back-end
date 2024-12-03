class TeamsParticipantsController < ApplicationController
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
  def auto_complete_for_user_name
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
  def list
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
  def new
    # Fetch the team for which a participant is to be added.
    @team = Team.find(params[:id])
  end

  # Adds a new participant to a team after validation.
  def create
    # Find the user by their name from the input.
    participant = find_user_by_name

    # Fetch the team using the provided ID.
    current_team = find_team_by_id

    # Return early if validation fails.
    return unless validate_participant_and_team(participant, current_team)

    # Add the participant to the team.
    add_participant_to_team(participant, current_team)

    # Redirect to the list of teams for the parent assignment or course.
    redirect_to controller: 'teams', action: 'list', id: current_team.parent_id
  end

  private

  # Helper method to find a user by their name.
  def find_user_by_name
    # Locate the user by their name.
    participant = User.find_by(name: params[:user][:name].strip)

    # Display an error if the user is not found.
    unless participant
      flash[:error] = user_not_found_error
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
                          Assignment.find(team.parent_id).valid_team_member?(participant)
                        else
                          Course.find(team.parent_id).valid_team_member?(participant)
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
  def add_participant_to_team(participant, team)
    # Add the participant to the team and handle the outcome.
    addition_result = team.add_member_with_handling(participant, team.parent_id)
    handle_addition_result(participant, team, addition_result)
  end

  # Handles the result of adding a participant to the team.
  def handle_addition_result(participant, team, addition_result)
    if addition_result == false
      flash[:error] = 'This team already has the maximum number of members.'
    else
      undo_link("The participant \"#{participant.name}\" has been successfully added to \"#{team.name}\".")
    end
  end

  # Generates an error message when a user is not found.
  def user_not_found_error
    new_user_url = url_for controller: 'users', action: 'new'
    "\"#{params[:user][:name].strip}\" is not defined. Please <a href=\"#{new_user_url}\">create</a> this user before continuing."
  end
end
