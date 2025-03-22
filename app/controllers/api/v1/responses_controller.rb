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

  def edit 

    action_params = { action: 'edit', id: params[:id], return: params[:return] }
    response_content = prepare_response_content(@map, params[:round], action_params)
  
    # Assign variables from response_content hash
    response_content.each { |key, value| instance_variable_set("@#{key}", value) }

    @largest_version_num  = Response.sort_by_version(@review_questions)
    @review_scores = @review_questions.map do |question|
      Answer.where(response_id: @response.response_id, question_id: question.id).first
    end

    render action: 'response'
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

    #Add back emailing logic
     if (@map.is_a? ReviewResponseMap) && @response.is_submitted && @response.significant_difference?
      @response.send_score_difference_email
    end

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
