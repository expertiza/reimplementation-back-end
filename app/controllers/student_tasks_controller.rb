class StudentTasksController < ApplicationController
  def action_allowed?
    current_user_has_student_privileges?
  end

  def list
    @student_tasks = StudentTask.from_user(current_user)
    render json: @student_tasks.map(&:as_json), status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  def view
    @student_task = StudentTask.from_participant_id(params[:id])
    return render json: { error: "Participant not found" }, status: :not_found unless @student_task

    render json: @student_task.as_json, status: :ok
  end

  def queue
    queue = build_queue_for_user(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless queue

    queue.ensure_response_objects!

    render json: queue.tasks.map(&:to_task_hash), status: :ok
  end

  def next_task
    queue = build_queue_for_user(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless queue

    queue.ensure_response_objects!

    next_task = queue.tasks.find { |t| !t.completed? }

    if next_task
      render json: next_task.to_task_hash, status: :ok
    else
      render json: { message: "All tasks completed" }, status: :ok
    end
  end

  def start_task
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: "ResponseMap not found" }, status: :not_found unless map

    participant = map.reviewer
    if participant.user_id != current_user.id
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    assignment = participant.assignment

    queue = TaskOrdering::TaskQueue.new(assignment, team_participant)
    tasks = queue.tasks

    current_task = tasks.find { |t| (rm = t.response_map) && rm.id == map.id }
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless current_task

    previous_tasks = tasks.take_while { |t| t != current_task }

    if previous_tasks.any? { |t| !t.completed? }
      return render json: { error: "Complete previous task first" }, status: :forbidden
    end

    current_task.ensure_response!

    render json: {
      message: "Task started",
      task: current_task.to_task_hash
    }, status: :ok
  end

  def build_queue_for_user(assignment_id)
    participant = Participant.find_by(
      user_id: current_user.id,
      parent_id: assignment_id
    )

    return nil unless participant

    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return nil unless team_participant

    TaskOrdering::TaskQueue.new(participant.assignment, team_participant)
  end
end
