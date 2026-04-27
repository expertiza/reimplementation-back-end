class StudentTasksController < ApplicationController
  def action_allowed?
    current_user_has_student_privileges?
  end

  def list
    render json: StudentTask.from_user(current_user), status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  def view
    render json: StudentTask.from_participant_id(params[:id]), status: :ok
  end

  def queue
    context = StudentTask.resolve_context_for_assignment(current_user, params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless context

    tasks = StudentTask.build_tasks(context)
    StudentTask.ensure_response_objects!(tasks)

    render json: tasks.map(&:to_h), status: :ok
  end

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
