# frozen_string_literal: true

class ResponsesController < ApplicationController
  prepend_before_action :set_response, only: %i[show update]
  before_action :find_and_authorize_map_for_create, only: %i[create]

  def action_allowed?
    case action_name
    when "create"
      true  # auth already handled by prepend_before_action above
    when "show", "update"
      @response && @response.map.reviewer.user_id == current_user.id
    else
      true
    end
  end

  def show
    render json: {
      response_id: @response.id,
      map_id: @response.map_id,
      task_type: @response.map.type,
      submitted: @response.is_submitted,
      additional_comment: @response.additional_comment
    }
  end

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

  def set_response
    @response = Response.find(params[:id])
  end

  # Runs before action_allowed? — handles both existence and authorization for create
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
 

  def response_update_params
    p = params.permit(:is_submitted, :additional_comment, :content, :round)
    p[:additional_comment] = p[:content] if p[:content].present?
    p.delete(:content)
    p
  end

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

    queue = TaskOrdering::TaskQueue.new(participant.assignment, team_participant)
    unless queue.map_in_queue?(map.id)
      render json: { error: "Response map is not a respondable task for this participant" }, status: :forbidden
      return false
    end

    unless queue.prior_tasks_complete_for?(map.id)
      render json: { error: "You must complete prior tasks before responding to this one" }, status: :forbidden
      return false
    end

    true
  end
end