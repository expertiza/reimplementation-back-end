class Api::V1::ResponsesController < ApplicationController
  include ResponseHelper
  before_action :set_response, only: %i[ show update destroy ]

  # GET /api/v1/responses
  def index
    @responses = Response.all

    render json: @responses
  end

  # GET /api/v1/responses/1
  def show
    render json: @response
  end

  # POST /api/v1/responses
  def create
    @response = Response.new(response_params)

    if @response.save
      render json: @response, status: :created, location: @response
    else
      render json: @response.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/responses/1
  def update
    if @response.update(response_params)
      render json: @response
    else
      render json: @response.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/responses/1
  def destroy
    @response.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_response
      @response = Api::V1::Response.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def response_params
      params.fetch(:response, {})
    end
end
