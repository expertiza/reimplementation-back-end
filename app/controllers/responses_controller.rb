# frozen_string_literal: true

class ResponsesController < ApplicationController
  prepend_before_action :set_response, only: %i[show update]
  before_action :find_and_authorize_map_for_create, only: %i[create]

  # Checks whether the current user can use the requested response action.
  def action_allowed?
    case action_name
    when "create"
      true  # auth already handled by before_action above
    when "show", "update"
      @response && @response.map.reviewer.user_id == current_user.id
    else
      true
    end
  end

  # Shows the response details for one task response.
  def show
    render json: {
      response_id: @response.id,
      map_id: @response.map_id,
      task_type: @response.map.type,
      submitted: @response.is_submitted,
      additional_comment: @response.additional_comment
    }
  end

  # Creates or reuses a response for the requested response map.
  def create
    return unless enforce_task_order!(@map)

    round = (params[:round].presence || 1).to_i
    response = Response.where(map_id: @map.id, round: round)
                       .order(:created_at)
                       .last || Response.new(map_id: @map.id, round: round)

    if params[:content].present? || params[:additional_comment].present?
      response.additional_comment = params[:content].presence || params[:additional_comment]
    end

    if response.save
      render json: { response_id: response.id, map_id: @map.id, round: response.round }, status: :created
    else
      render json: { errors: response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Updates the saved response with submission details or comments.
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

  # Finds the response used by show and update.
  def set_response
    @response = Response.find(params[:id])
  end

  # Finds the response map and checks that the current user owns it.
  def find_and_authorize_map_for_create
    @map = ResponseMap.find_by(id: params[:response_map_id])
    unless @map
      render json: { error: "ResponseMap not found" }, status: :not_found
      return
    end

    unless @map.reviewer.user_id == current_user.id
      render json: { error: "You are not authorized to create this responses" }, status: :forbidden
    end
  end


  # Allows only the response fields that can be changed by this controller.
  def response_update_params
    p = params.permit(:is_submitted, :additional_comment, :content, :round)
    p[:additional_comment] = p[:content] if p[:content].present?
    p.delete(:content)
    p
  end

  # Makes sure earlier tasks are finished before this task can be changed.
  def enforce_task_order!(map)
    participant = map.reviewer
    unless participant.user_id == current_user.id
      render json: { error: "Unauthorized" }, status: :forbidden
      return false
    end

    context = StudentTask.resolve_context_for_participant(participant)
    unless context
      render json: { error: "TeamsParticipant not found for reviewer" }, status: :forbidden
      return false
    end

    tasks = StudentTask.build_tasks(context)
    current_task = StudentTask.find_task_for_map(tasks, map.id)
    unless current_task
      render json: { error: "Response map is not a respondable task for this participant" }, status: :forbidden
      return false
    end

    unless StudentTask.prior_tasks_complete?(tasks, current_task)
      render json: { error: "Complete previous task first" }, status: :precondition_failed
      return false
    end

    true
  end
end