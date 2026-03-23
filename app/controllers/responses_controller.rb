class ResponsesController < ApplicationController
  before_action :set_response, only: [:show, :edit, :update, :destroy]

  # GET /responses/1
  def show
    render json: {
      response_id: @response.id,
      map_id: @response.map_id,
      task_type: @response.map.type,
      submitted: @response.is_submitted,
      content: @response.content # include rubric/answers
    }
  end

  # POST /responses
  # Idempotent creation of a response for a quiz or review task
  def create
    map = ResponseMap.find(params[:response_map_id])
    round = params[:round] || 1

    # Find latest draft or create a new response
    response = Response.where(map_id: map.id, round: round)
                       .order(:created_at)
                       .last || Response.new(map_id: map.id, round: round)

    # Assign attributes from params
    response.content = params[:content] if params[:content]

    if response.save
      render json: { response_id: response.id, map_id: map.id }, status: :created
    else
      render json: { errors: response.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_response
    @response = Response.find(params[:id])
  end
end