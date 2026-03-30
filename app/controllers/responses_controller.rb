# frozen_string_literal: true

class ResponsesController < ApplicationController
  # This controller enforces task ordering using TaskOrdering::TaskQueue.
  # A participant cannot submit a response for a task unless all prior tasks in their queue are completed.
  prepend_before_action :set_response, only: %i[show update]
  
  # Determines whether the current user is allowed to perform the action.
  # Authorization is based on whether the current user is the reviewer associated with the ResponseMap.
  def action_allowed?
    case action_name
    when "create"
      # Allow create only if the current user is the reviewer assigned to the ResponseMap
      map = ResponseMap.find_by(id: params[:response_map_id])
      map && map.reviewer.user_id == current_user.id
    when "show", "update"
      # Allow show/update only if the response belongs to the current user
      @response && @response.map.reviewer.user_id == current_user.id
    else
      true
    end
  end

  # Returns response metadata used by frontend/task UI.
  # task_type is derived from ResponseMap type (ReviewResponseMap, QuizResponseMap)
  def show
    render json: {
      response_id: @response.id,
      map_id: @response.map_id,
      task_type: @response.map.type,
      submitted: @response.is_submitted,
      additional_comment: @response.additional_comment
    }
  end

  # Creates or retrieves an existing Response for the given ResponseMap and round.
  # Also enforces task ordering before allowing response creation.
  def create
    map = ResponseMap.find_by(id: params[:response_map_id])
    return render json: { error: "ResponseMap not found" }, status: :not_found unless map
    
    # Ensure participant is allowed to work on this task based on queue ordering
    return unless enforce_task_order!(map)

    # Default round is 1 unless explicitly provided
    round = (params[:round].presence || 1).to_i

    # Retrieve latest response for this map and round if it exists, otherwise initialize a new Response object.
    # May allow multiple responses per round, so select the most recent one.
    response = Response.where(map_id: map.id, round: round)
                       .order(:created_at)
                       .last || Response.new(map_id: map.id, round: round)

    # Support both 'content' and 'additional_comment' parameters.
    if params[:content].present? || params[:additional_comment].present?
      response.additional_comment = params[:content].presence || params[:additional_comment]
    end

    # Save response and return identifiers
    if response.save
      render json: { response_id: response.id, map_id: map.id, round: response.round }, status: :created
    else
      render json: { errors: response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Task ordering is enforced before allowing submission.
  def update
    return unless enforce_task_order!(@response.map)

    if @response.update(response_update_params)
      render json: {
        response_id: @response.id,
        map_id: @response.map_id,
        submitted: @response.is_submitted,
        additional_comment: @response.additional_comment
      }, status: :ok
    else
      render json: { errors: @response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Loads Response before show/update actions
  def set_response
    @response = Response.find(params[:id])
  end

  # Permits response parameters and maps 'content' to 'additional_comment'
  def response_update_params
    p = params.permit(:is_submitted, :additional_comment, :content, :round)
    p[:additional_comment] = p[:content] if p[:content].present?
    p.delete(:content)
    p
  end

  # Enforces task queue ordering and authorization. Checks:
  # 1. Current user is the reviewer assigned to the ResponseMap
  # 2. Reviewer has a TeamsParticipant record
  # 3. ResponseMap exists in the participant's task queue
  # 4. All prior tasks in the queue are completed
  # Returns true if task can proceed, otherwise renders error and returns false.
  def enforce_task_order!(map)
    participant = map.reviewer
    unless participant.user_id == current_user.id
      render json: { error: "Unauthorized" }, status: :forbidden
      return false
    end

    team_participant = TeamsParticipant.find_by(participant_id: participant.id)
    unless team_participant
      render json: { error: "TeamsParticipant not found for reviewer" }, status: :forbidden
      return false
    end

    # Build task queue for this participant and assignment
    queue = TaskOrdering::TaskQueue.new(participant.assignment, team_participant)
    # Ensure this response map is a valid task for the participant
    unless queue.map_in_queue?(map.id)
      render json: { error: "Response map is not a respondable task for this participant" }, status: :forbidden
      return false
    end

    # Enforce sequential task completion (quiz before review, etc.)
    unless queue.prior_tasks_complete_for?(map.id)
      render json: { error: "Complete previous task first" }, status: :precondition_failed
      return false
    end

    true
  end
end
