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

  # Returns ordered list of respondable tasks (quiz, review)
  # GET /student_tasks/:assignment_id/queue
  def queue
    queue = build_queue_for_user(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless queue

    queue.ensure_response_objects!

    render json: queue.tasks.map(&:to_task_hash), status: :ok
  end

  # GET /student_tasks/:participant_id/next_task
  # Returns the next incomplete task in the sequence
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

  # POST /student_tasks/start_task
  # Ensures task can be started (order enforcement)
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

    current_task = tasks.find { |t| t.response_map.id == map.id }
    previous_tasks = tasks.take_while { |t| t != current_task }

    # Enforce ordering: all previous tasks must be completed
    if previous_tasks.any? { |t| !t.completed? }
      return render json: { error: "Complete previous task first" }, status: :forbidden
    end

    # Ensure response exists
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
