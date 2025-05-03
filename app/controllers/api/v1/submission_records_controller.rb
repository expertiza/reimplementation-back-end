class SubmissionRecordsController < ApplicationController
  include AuthorizationHelper

  # Set up before_action callbacks
  before_action :set_submission_record, only: %i[show edit update destroy]
  before_action :set_assignment_team, only: [:index]
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

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
    if current_user_has_student_privileges? && (@assignment_team.user_id == current_user.id || @assignment_team.users.include?(current_user))
      return true
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
    render json: @submission_records, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /submission_records/:id
  def show
    render json: @submission_record, status: :ok
  end

  # POST /submission_records
  def create
    @submission_record = SubmissionRecord.new(submission_record_params)
    if @submission_record.save
      render json: @submission_record, status: :created
    else
      render json: @submission_record.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /submission_records/:id
  def update
    if @submission_record.update(submission_record_params)
      render json: @submission_record, status: :ok
    else
      render json: @submission_record.errors, status: :unprocessable_entity
    end
  end

  # DELETE /submission_records/:id
  def destroy
    @submission_record.destroy
    render json: { message: 'Submission record deleted successfully' }, status: :no_content
  end

  private

  # Sets up the assignment team and assignment for the current request
  # Used by the index action to ensure proper context for viewing records
  def set_assignment_team
    @assignment_team = AssignmentTeam.find(params[:team_id])
    @assignment = @assignment_team.parent
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Assignment team not found' }, status: :not_found
  end

  # Sets up a single submission record for show/edit/update/destroy actions
  def set_submission_record
    @submission_record = SubmissionRecord.find(params[:id])
  end

  def submission_record_params
    params.require(:submission_record).permit(:team_id, :operation, :user, :content, :created_at)
  end

  def not_found
    render json: { error: 'Submission record not found' }, status: :not_found
  end
end
