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
  


  def queue
    # Build the task queue for the current user and assignment.
    # Returns nil if the user is not a participant in the assignment.
    queue = build_queue_for_user(params[:assignment_id])

    # If no queue is found, the user is either not authorized or not associated with the assignment.
    return render json: { error: "Not authorized or not found" }, status: :not_found unless queue

    # Ensure all ResponseMaps and Responses exist before returning tasks.
    queue.ensure_response_objects!

    render json: queue.tasks.map(&:to_task_hash), status: :ok
  end

  def next_task
    # Build the task queue for the current user and assignment.
    queue = build_queue_for_user(params[:assignment_id])
    return render json: { error: "Not authorized or not found" }, status: :not_found unless queue

    # Ensure response objects exist before checking completion status.
    queue.ensure_response_objects!

    # Find the first task in the queue that has not been completed.
    next_task = queue.tasks.find { |t| !t.completed? }

    if next_task
      # Return the next incomplete task.
      render json: next_task.to_task_hash, status: :ok
    else
      # If all tasks are completed, return completion message.
      render json: { message: "All tasks completed" }, status: :ok
    end
  end

  def start_task
    # Find the ResponseMap associated with the task being started.
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: "ResponseMap not found" }, status: :not_found unless map

    # Ensure the current user is the reviewer assigned to this ResponseMap.
    participant = map.reviewer
    if participant.user_id != current_user.id
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    # Build the task queue for this participant and assignment.
    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    assignment = participant.assignment

    queue = TaskOrdering::TaskQueue.new(assignment, team_participant)
    # Retrieve all tasks in the queue.
    tasks = queue.tasks

    # Find the current task corresponding to the ResponseMap.
    current_task = tasks.find { |t| (rm = t.response_map) && rm.id == map.id }
    return render json: { error: "Task not in respondable queue" }, status: :not_found unless current_task

    # Get all tasks that appear before the current task in the queue.
    previous_tasks = tasks.take_while { |t| t != current_task }

    # Ensure all previous tasks are completed before starting this one.
    if previous_tasks.any? { |t| !t.completed? }
      return render json: { error: "Complete previous task first" }, status: :forbidden
    end

    # Ensure a Response record exists for this task.
    current_task.ensure_response!

    # Return confirmation that the task has started.
    render json: {
      message: "Task started",
      task: current_task.to_task_hash
    }, status: :ok
  end

  def build_queue_for_user(assignment_id)
    # Find the participant record for the current user in the assignment.
    participant = Participant.find_by(
      user_id: current_user.id,
      parent_id: assignment_id
    )

    # Return nil if the user is not a participant in the assignment.
    return nil unless participant

    # Find the TeamsParticipant record associated with the participant.
    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return nil unless team_participant

    # Build and return the task queue for this participant.
    TaskOrdering::TaskQueue.new(participant.assignment, team_participant)
  end
end
