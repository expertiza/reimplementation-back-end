class StudentTasksController < ApplicationController
  before_action :set_student_task, only: %i[show view request_revision]

  def action_allowed?
    current_user_has_student_privileges?
  end

  def index
    list
  end

  def list
    render json: StudentTask.from_user(current_user), status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  def view
    show
  end

  def request_revision
    return render json: { error: 'Revision requests require a team submission' }, status: :unprocessable_entity unless @student_task.team
    return render json: { error: 'Revision requests are not available for this task' }, status: :unprocessable_entity unless @student_task.can_request_revision

    revision_request = RevisionRequest.new(
      participant: @participant,
      team: @student_task.team,
      assignment: @participant.assignment,
      comments: params[:comments]
    )

    if revision_request.save
      @student_task = StudentTask.from_participant(@participant)
      render json: { message: 'Revision request submitted successfully', revision_request: revision_request.as_json, student_task: @student_task.as_json }, status: :created
    else
      render json: { error: revision_request.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  private

  def set_student_task
    @participant = AssignmentParticipant.find_by(id: params[:id])
    return render json: { error: 'Student task not found' }, status: :not_found unless @participant
    return render json: { error: 'You are not authorized to access this student task' }, status: :forbidden unless @participant.user_id == current_user.id

    @student_task = StudentTask.from_participant(@participant)
  end
end
