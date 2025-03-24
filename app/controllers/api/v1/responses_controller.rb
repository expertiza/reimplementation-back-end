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
    @map_id = 1
    puts @map_id
    #@map = ResponseMap.find(params[:id])
    #attributes = prepare_response_content(@map, 'New', true)
    #attributes.each do |key, value|
    #  instance_variable_set("@#{key}", value)
    #end
    #@response = find_or_create_response
    #questions = @response.sort_items(@questionnaire.items)
    #@total_score = total_cake_score(@response)
    #init_answers(@response, questions)
    #render action: 'response'
  end

  # POST /api/v1/responses
  def create
    @map = find_map
    @questionnaire = find_questionnaire
    is_submitted = (params[:isSubmit] == 'Yes')

    @response = find_or_create_response(is_submitted)
    was_submitted = @response.is_submitted

    update_response(is_submitted)
    process_items if params[:responses]

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
    puts "find_map method"
    map_id = params[:map_id] || params[:id]

    ResponseMap.find_by(id: map_id)
  end

  def find_questionnaire
    if params[:review][:questionnaire_id]
      questionnaire = Questionnaire.find(params[:review][:questionnaire_id])
    else
      questionnaire = nil
    end
    questionnaire
  end

  def find_or_create_response(is_submitted = false)
    response = Response.where(map_id: @map.map_id).order(created_at: :desc).first
    if response.nil?
      response = Response.create(map_id: @map.id, additional_comment: params[:review][:comments],
                                 is_submitted: is_submitted)
    end
    response
  end

  def update_response(is_submitted)
    @response.update(additional_comment: params[:review][:comments], is_submitted: is_submitted)
  end

  def process_items
    items = sort_items(@questionnaire.items)
    items = @questionnaire.items
    create_answers(params, items)
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
    params.require(:response).permit(
      :isSubmit,
      :map_id,
      :id,
      review: [:comments, :questionnaire_id],
      responses: {}, # Adjust based on structure
      save_options: {},
      return: {}
    )
  end
end
