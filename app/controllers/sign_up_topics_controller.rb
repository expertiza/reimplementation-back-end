class SignUpTopicsController < ApplicationController
  before_action :set_sign_up_topic, only: %i[ show update ]

  # GET /sign_up_topics?assignment_id=&topic_ids[]=
  # Retrieve SignUpTopics by two query parameters - assignment_id (compulsory) and an array of topic_ids (optional)
  def index
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].nil?
      @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id])
      render json: @sign_up_topics, status: :ok
    else
      @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
      render json: @sign_up_topics, status: :ok
    end
    # render json: {message: 'All selected topics have been loaded successfully.', sign_up_topics: @stopics}, status: 200
  end

  # POST /sign_up_topics
  # The create method allows the instructor to create a new topic
  # params[:sign_up_topic][:topic_identifier] follows a json format
  # The method takes inputs and outputs the if the topic creation was successful.
  def create
    @sign_up_topic = SignUpTopic.new(sign_up_topic_params)

    @assignment = Assignment.find_by(id: @sign_up_topic.assignment_id)
    if @sign_up_topic.assignment_id.blank? || @assignment.nil?
      render json: { message: 'Assignment ID is invalid or missing.' }, status: :unprocessable_entity
      return
    end

    @sign_up_topic.micropayment = micropayment_value if @assignment.microtask?
    if @sign_up_topic.save
      # undo_link "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "
      render json: { message: "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. " }, status: :created
    else
      render json: { message: @sign_up_topic.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /sign_up_topics/1
  # updates parameters present in sign_up_topic_params.
  def update
    assignment = Assignment.find_by(id: @sign_up_topic.assignment_id)
    @sign_up_topic.micropayment = micropayment_value if assignment&.microtask?

    if @sign_up_topic.update(sign_up_topic_params)
      render json: { message: "The topic: \"#{@sign_up_topic.topic_name}\" has been updated successfully. " }, status: 200
    else
      render json: @sign_up_topic.errors, status: :unprocessable_entity
    end
  end

  # Show a SignUpTopic by ID
  def show
    render json: @sign_up_topic, status: :ok
  end

  # Similar to index method, this method destroys SignUpTopics by two query parameters
  # assignment_id is compulsory.
  # topic_ids[] is optional
  def destroy
    # render json: {message: @sign_up_topic}
    # filters topics based on assignment id (required) and topic identifiers (optional)
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].nil?
      @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id])
      # render json: @sign_up_topics, status: :ok
    else
      @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
      # render json: @sign_up_topics, status: :ok
    end

    if @sign_up_topics.each(&:delete)
      render json: { message: "The topic has been deleted successfully. " }, status: :no_content
    else
      render json: @sign_up_topic.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_sign_up_topic
    @sign_up_topic = SignUpTopic.find(params[:id])
  end

  # Temporary compatibility shim for legacy frontend naming.
  # Remove once the frontend consistently submits `sign_up_topic`.
  def topic_payload
    params[:project_topic] || params[:sign_up_topic] || ActionController::Parameters.new
  end

  def micropayment_value
    topic_payload[:micropayment] || params[:micropayment]
  end

  # Only allow a list of trusted parameters through.
  def sign_up_topic_params
    topic_payload.permit(
      :topic_identifier,
      :category,
      :topic_name,
      :max_choosers,
      :assignment_id,
      :description,
      :link
    )
  end
end
