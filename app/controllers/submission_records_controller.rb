class SubmissionRecordsController < ApplicationController
  include AuthorizationHelper

  # Set up before_action callbacks
  before_action :set_submission_record, only: %i[show edit update destroy]
  before_action :set_assignment_team, only: [:index]

  # Determines if the current user has permission to access submission records
  # Returns true for:
  # - Administrators
  # - Instructors teaching the assignment
  # - TAs assigned to the assignment
  # - Students who are members of the team
  def action_allowed?
    # Allow access to instructors, TAs, and admins
    return true if current_user_has_admin_privileges?
    return true if current_user_has_instructor_privileges? && current_user_instructs_assignment?(@assignment)
    return true if current_user_has_ta_privileges? && current_user_has_ta_mapping_for_assignment?(@assignment)

    # Allow students to view their own team's submission records
    if current_user_has_student_privileges?
      return true if @assignment_team.user_id == current_user.id || @assignment_team.users.include?(current_user)
    end

    false
  end

  # Displays submission records for a specific assignment team
  # - Fetches all records for the team
  # - Orders them by most recent first
  # - Makes them available to the view as @submission_records
  def index
    @submission_records = SubmissionRecord.where(team_id: @assignment_team.id)
                                        .order(created_at: :desc) # Order by most recent first
  end

  private

  # Sets up the assignment team and assignment for the current request
  # Used by the index action to ensure proper context for viewing records
  def set_assignment_team
    @assignment_team = AssignmentTeam.find(params[:team_id])
    @assignment = @assignment_team.parent
  end

  # Sets up a single submission record for show/edit/update/destroy actions
  def set_submission_record
    @submission_record = SubmissionRecord.find(params[:id])
  end
end