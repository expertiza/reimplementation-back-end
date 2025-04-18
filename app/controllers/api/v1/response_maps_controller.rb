class ResponseMapsController < ApplicationController
  before_action :set_response_map, only: [:show, :update, :destroy, :send_email]

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

    if @response_map.save
      render json: @response_map, status: :created
    else
      render json: @response_map.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/response_maps/:id
  def update
    if @response_map.update(response_map_params)
      render json: @response_map
    else
      render json: @response_map.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/response_maps/:id
  def destroy
    @response_map.destroy
    head :no_content
  end

  # POST /api/v1/response_maps/:id/send_email
  def send_email
    assignment = Assignment.find(params[:assignment_id])
    @response_map.send_email(assignment)
    render json: { message: 'Email sent successfully' }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
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
end
