# app/controllers/api/v1/response_maps_controller.rb
class Api::V1::ResponseMapsController < ApplicationController
  before_action :set_response_map, only: [:show, :update, :destroy, :submit_response]

  # GET /api/v1/response_maps
  def index
    @response_maps = ResponseMap.all
    render json: @response_maps
  end

  # GET /api/v1/response_maps/:id
  def show
    render json: @response_map
  end

  # POST /api/v1/response_maps
  def create
    @response_map = ResponseMap.new(response_map_params)
    persist_and_respond(@response_map, :created)
  end

  # PATCH/PUT /api/v1/response_maps/:id
  def update
    @response_map.assign_attributes(response_map_params)
    persist_and_respond(@response_map, :ok)
  end

  # DELETE /api/v1/response_maps/:id
  def destroy
    @response_map.destroy
    head :no_content
  end

  # POST /api/v1/response_maps/:id/submit_response
  def submit_response
    @response = @response_map.responses.find_or_initialize_by(id: params[:response_id])
    @response.assign_attributes(response_params)
    @response.is_submitted = true

    if @response.save
      # send feedback email now that it’s marked submitted
      FeedbackEmailService.new(@response_map, @response_map.assignment).call
      render json: { message: 'Response submitted successfully, email sent' }, status: :ok
      handle_submission(@response_map)
    else
      render json: { errors: @response.errors }, status: :unprocessable_entity
    end
  end

  def handle_submission(map)
    FeedbackEmailService.new(map, map.assignment).call
    render json: { message: 'Response submitted successfully, email sent' }, status: :ok
    rescue StandardError => e
    Rails.logger.error "FeedbackEmail failed: #{e.message}"
    render json: { message: 'Response submitted, but email failed' }, status: :ok
    end

  # GET /api/v1/response_maps/response_report/:assignment_id
  def response_report
    assignment_id = params[:assignment_id]
    report = ResponseMap.response_report(assignment_id, params[:type])
    render json: report
  end

  private

  def set_response_map
    @response_map = ResponseMap.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Response map not found' }, status: :not_found
  end

  def response_map_params
    params.require(:response_map).permit(:reviewee_id, :reviewer_id, :reviewed_object_id)
  end

  def response_params
    params.require(:response).permit(
      :additional_comment,
      :round,
      :is_submitted,
      scores_attributes: [:answer, :comments, :question_id]
    )
  end

  def persist_and_respond(record, success_status)
    if record.save
      handle_submission(record) if record.is_submitted?
      render json: record, status: success_status
    else
      render json: record.errors, status: :unprocessable_entity
    end
  end
end