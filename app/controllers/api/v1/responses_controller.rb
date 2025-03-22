class Api::V1::ResponsesController < ApplicationController
  include ResponsesHelper
  include ScorableHelper
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

  # GET /api/v1/json?response_id=xx
  def json
    response_id = params[:response_id] if params.key?(:response_id)
    response = Response.find(response_id)
    render json: response
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

    return render nothing: true unless action_allowed?

    
    @response.update_attribute('additional_comment', params[:review][:comments])
    @questionnaire = @response.questionnaire_by_answer(@response.scores.first)
    
    questions = sort_items(@questionnaire.questions)

    # for some rubrics, there might be no questions but only file submission (Dr. Ayala's rubric)
    create_answers(params, questions) unless params[:responses].nil?
    if params['isSubmit'] && params['isSubmit'] == 'Yes'
      @response.update_attribute('is_submitted', true)
    end

    # Add back emailing logic
    # if (@map.is_a? ReviewResponseMap) && @response.is_submitted && @response.significant_difference?
    #   @response.notify_instructor_on_difference
    # end

    rescue StandardError => e
      msg = "Your response was not saved. Cause:189 #{$ERROR_INFO}"
    end

    redirect_to controller: 'responses', action: 'save', id: @map.map_id,
              return: params.permit(:return)[:return], msg: msg, review: params.permit(:review)[:review],
              save_options: params.permit(:save_options)[:save_options]

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
