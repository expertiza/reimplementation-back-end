class StudentTasksController < ApplicationController
  def action_allowed?
    current_user_has_student_privileges?
  end

  def list
    @student_tasks = StudentTask.from_user(current_user)
    render json: @student_tasks, status: :ok
  end

  def show
    render json: @student_task, status: :ok
  end

  def view
    @student_task = StudentTask.from_participant_id(params[:id])
    render json: @student_task, status: :ok
  end

  def queue
    assignment = Assignment.find_by(id: params[:assignment_id])
    return render json: { error: 'Assignment not found' }, status: :not_found unless assignment

    participant = Participant.find_by(user_id: current_user.id, parent_id: assignment.id)
    return render json: { error: 'Participant not found' }, status: :not_found unless participant

    teams_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return render json: { error: 'TeamsParticipant not found' }, status: :not_found unless teams_participant

    queue = TaskOrdering::TaskQueue.new(assignment, teams_participant)
    maps = ResponseMap.where(id: queue.map_ids)
    render json: maps, status: :ok
  end

  def next_task
    assignment = Assignment.find_by(id: params[:assignment_id])
    return render json: { error: 'Assignment not found' }, status: :not_found unless assignment

    participant = Participant.find_by(user_id: current_user.id, parent_id: assignment.id)
    return render json: { error: 'Participant not found' }, status: :not_found unless participant

    teams_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return render json: { error: 'TeamsParticipant not found' }, status: :not_found unless teams_participant

    queue = TaskOrdering::TaskQueue.new(assignment, teams_participant)
    next_map_id = queue.map_ids.find { |id| !Response.where(map_id: id).any?(&:is_submitted) }

    if next_map_id
      render json: ResponseMap.find(next_map_id), status: :ok
    else
      render json: { message: 'All tasks complete' }, status: :ok
    end
  end

  def start_task
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: 'ResponseMap not found' }, status: :not_found unless map

    participant = map.reviewer
    return render json: { error: 'Unauthorized' }, status: :forbidden unless participant.user_id == current_user.id

    teams_participant = TeamsParticipant.find_by(participant_id: participant.id)
    return render json: { error: 'TeamsParticipant not found' }, status: :forbidden unless teams_participant

    queue = TaskOrdering::TaskQueue.new(participant.assignment, teams_participant)
    return render json: { error: 'Map not in queue' }, status: :forbidden unless queue.map_in_queue?(map.id)
    return render json: { error: 'Complete previous task first' }, status: :forbidden unless queue.prior_tasks_complete_for?(map.id)

    render json: map, status: :ok
  end
end
