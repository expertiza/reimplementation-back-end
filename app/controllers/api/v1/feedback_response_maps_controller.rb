class Api::V1::FeedbackResponseMapsController < ApplicationController
  before_action :set_feedback_response_map, only: [:show, :update, :destroy]

  # GET /api/v1/feedback_response_maps
  def index
    @feedback_response_maps = FeedbackResponseMap.all
    render json: @feedback_response_maps
  end

  # GET /api/v1/feedback_response_maps/:id
  def show
    render json: @feedback_response_map
  end

  # POST /api/v1/feedback_response_maps
  def create
    @feedback_response_map = FeedbackResponseMap.new(feedback_response_map_params)

    if @feedback_response_map.save
      render json: @feedback_response_map, status: :created
    else
      render json: @feedback_response_map.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/feedback_response_maps/:id
  def update
    if @feedback_response_map.update(feedback_response_map_params)
      render json: @feedback_response_map
    else
      render json: @feedback_response_map.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/feedback_response_maps/:id
  def destroy
    @feedback_response_map.destroy
    head :no_content
  end

  # GET /api/v1/feedback_response_maps/response_report/:assignment_id
  def response_report
    assignment_id = params[:assignment_id]
    report = FeedbackResponseMap.feedback_response_report(assignment_id, params[:type])
    render json: report
  end

  private

  def set_feedback_response_map
    @feedback_response_map = FeedbackResponseMap.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Feedback response map not found' }, status: :not_found
  end

  def feedback_response_map_params
    params.require(:feedback_response_map).permit(:reviewee_id, :reviewer_id, :reviewed_object_id)
  end
end 