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
    @map = find_map
    @questionnaire = find_questionnaire
    is_submitted = (params[:isSubmit] == 'Yes')

    @response = find_or_create_response(is_submitted)
    was_submitted = @response.is_submitted

    update_response(is_submitted)
    #process_questions if params[:responses]

    notify_instructor_if_needed(was_submitted)

    redirect_to_response_save
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
  def find_map
    map_id = params[:map_id] || params[:id]
    return nil if map_id.nil?
  
    ResponseMap.find_by(id: map_id)
  rescue ActiveRecord::RecordNotFound
    nil
  end
  def find_questionnaire
    if params[:review][:questionnaire_id]
      questionnaire = Questionnaire.find(params[:review][:questionnaire_id])
    else
      questionnaire = nil

    end
    questionnaire
  end

  def find_or_create_response(is_submitted)
    response = Response.where(map_id: @map.id).order(created_at: :desc).first
    if response.nil?
      response = Response.create(map_id: @map.id, additional_comment: params[:review][:comments],
                                 is_submitted: is_submitted)
    end
    response
  end

  def update_response(is_submitted)
    @response.update(additional_comment: params[:review][:comments], is_submitted: is_submitted)
  end

  def process_questions
    questions = sort_questions(@questionnaire.questions)
    create_answers(params, questions)
  end

  def notify_instructor_if_needed(was_submitted)
    if @map.is_a?(ReviewResponseMap) && !was_submitted && @response.is_submitted && @response.significant_difference?
      @response.notify_instructor_on_difference
      @response.email
    end
  end

  def redirect_to_response_save
    msg = 'Your response was successfully saved.'
    error_msg = ''
    redirect_to controller: 'response', action: 'save', id: @map.map_id,
                return: params.permit(:return)[:return], msg: msg, error_msg: error_msg, review: params.permit(:review)[:review], save_options: params.permit(:save_options)[:save_options]
  end  

    # Use callbacks to share common setup or constraints between actions.
    def set_response
      @response = Api::V1::Response.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def response_params
      params.fetch(:response, {})
    end
end
