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

  # Returns the full ordered task queue for an assignment.
  def queue
    context = StudentTask.resolve_context_for_assignment(current_user, params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    tasks = StudentTask.build_tasks(context)
    StudentTask.ensure_response_objects!(tasks)

    render json: tasks.map(&:to_h), status: :ok
  end

  # Returns the next unfinished task in the assignment queue.
  def next_task
    context = StudentTask.resolve_context_for_assignment(current_user, params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    tasks = StudentTask.build_tasks(context)
    StudentTask.ensure_response_objects!(tasks)
    next_task = tasks.find { |task| !task.completed? }

    if next_task
      render json: next_task.to_h, status: :ok
    else
      render json: { message: "All tasks completed" }, status: :ok
    end
  end

  # Starts a task after checking that earlier tasks are complete.
  def start_task
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: "ResponseMap not found" }, status: :not_found unless map

    participant = map.reviewer
    return render json: { error: "Unauthorized" }, status: :forbidden if participant.user_id != current_user.id

    context = StudentTask.resolve_context_for_participant(participant)
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless context

    tasks = StudentTask.build_tasks(context)
    current_task = StudentTask.find_task_for_map(tasks, map.id)
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless current_task

    unless StudentTask.prior_tasks_complete?(tasks, current_task)
      return render json: { error: "Complete previous task first" }, status: :forbidden
    end

    current_task.ensure_response!

    render json: {
      message: "Task started",
      task: current_task.to_h
    }, status: :ok
  end
end
