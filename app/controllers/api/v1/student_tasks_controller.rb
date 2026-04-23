class Api::V1::StudentTasksController < ApplicationController
  before_action :set_student_task, only: %i[show view]

  def action_allowed?
    has_privileges_of?('Student')
  end

  def index
    render json: StudentTask.from_user(current_user), status: :ok
  end

  def list
    index
  end

  def show
    render json: @student_task, status: :ok
  end

  def view
    show
  end

  private

  def set_student_task
    participant = Participant.includes(:team, assignment: :course).find_by(id: params[:id])
    return render json: { error: 'Student task not found' }, status: :not_found unless participant
    return render json: { error: 'You are not authorized to access this student task' }, status: :forbidden unless participant.user_id == current_user.id

    @student_task = StudentTask.from_participant(participant)
  end
end
