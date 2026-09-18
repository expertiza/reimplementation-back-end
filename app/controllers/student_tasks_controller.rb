class StudentTasksController < ApplicationController

  # List retrieves all student tasks associated with the current logged-in user.
  def action_allowed?
    current_user_has_student_privileges?
  end
  def list
    @student_tasks = StudentTask.tasks(current_user)
    render json: @student_tasks, status: :ok
  end

  # Retrieves a StudentTask by AssignmentParticipant ID.
  # Delegates lookup and preloading to from_participant_id so the find_by +
  # nil-guard + create_from_participant logic is not duplicated here.
  def show
    @student_task = StudentTask.from_participant_id(params[:id])

    if @student_task.nil?
      render json: { error: "Participant not found" }, status: :not_found
      return
    end

    if @student_task.participant.user_id != current_user.id
      render json: { error: "Unauthorized access to participant's task" }, status: :forbidden
      return
    end

    render json: @student_task, status: :ok
  end

end
