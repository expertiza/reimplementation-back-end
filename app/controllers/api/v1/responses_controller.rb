class Api::V1::ResponsesController < ApplicationController
  include ResponsesHelper
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

  def new
    @map = ResponseMap.find(params[:id])
    attributes = prepare_response_content(map, 'New', true)
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
    if @assignment
      @stage = @assignment.current_stage(SignedUpTeam.topic_id(@participant.parent_id, @participant.user_id))
    end

    questions = sort_questions(@questionnaire.questions)
    @total_score = total_cake_score
    init_answers(@response, questions)
    render action: 'response'
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

  def new_feedback
    find_response
    if @review
      @reviewer = AssignmentParticipant.where(user_id: session[:user].id, parent_id: review.map.assignment.id).first
      find_FeedbackResponseMap_or_create_new
      render json: @response, status: 201, location: @response
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_response
      @response = Api::V1::Response.find(params.expect(:id))
    end

    def find_response
      @review = Response.find(params[:id]) unless params[:id].nil?
    end

    # Only allow a list of trusted parameters through.
    def response_params
      params.fetch(:response, {})
    end
end
