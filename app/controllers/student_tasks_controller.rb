class StudentTasksController < ApplicationController

  # List retrieves all student tasks associated with the current logged-in user.
  def action_allowed?
    current_user_has_student_privileges?
  end
  def list
    # Retrieves all tasks that belong to the current user.
    @student_tasks = StudentTask.from_user(current_user)
    # Render the list of student tasks as JSON.
    render json: @student_tasks, status: :ok
  end

  def index
    participant = AssignmentParticipant.find_by(
      user_id: current_user.id,
      parent_id: params[:assignment_id]
    )

    tasks = participant.respondable_tasks

    render json: tasks.map do |t|
      response = Response.where(map_id: t[:response_map_id]).order(:created_at).last
      {
        task_type: t[:task_type],
        completed: response&.is_submitted || false
      }
    end
  end

  def show
    render json: @student_task, status: :ok
  end

  # The view function retrieves a student task based on a participant's ID.
  # It is meant to provide an endpoint where tasks can be queried based on participant ID.
  def view
    # Retrieves the student task where the participant's ID matches the provided parameter.
    # This function will be used for clicking on a specific student task to "view" its details.
    @student_task = StudentTask.from_participant_id(params[:id])
    # Render the found student task as JSON.
    render json: @student_task, status: :ok
  end

  def next_task
    participant = AssignmentParticipant.find_by(
      user_id: current_user.id,
      parent_id: params[:assignment_id]
    )

    tasks = participant.respondable_tasks

    next_task = tasks.find do |t|
      response = Response.where(map_id: t[:response_map_id]).order(:created_at).last
      !(response&.is_submitted)
    end

    if next_task
      response = Response.where(map_id: next_task[:response_map_id]).order(:created_at).last
      render json: {
        task_type: next_task[:task_type],
        map_id: next_task[:response_map_id],
        response_id: response&.id
      }
    else
      render json: { message: "All tasks completed" }
    end
  end

end
