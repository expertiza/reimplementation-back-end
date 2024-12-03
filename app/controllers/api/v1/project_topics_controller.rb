class Api::V1::ProjectTopicsController < ApplicationController
  before_action :set_project_topic, only: %i[ show update ]

  # GET /api/v1/project_topics?assignment_id=&topic_ids[]=
  # Retrieve ProjectTopics by two query parameters - assignment_id (compulsory) and an array of topic_ids (optional)
  def index
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].nil?
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id])
      render json: @project_topics, status: :ok
    else
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
      render json: @project_topics, status: :ok
    end
  end

  # POST /project_topics
  # The create method allows the instructor to create a new topic
  # params[:project_topic][:topic_identifier] follows a json format
  # The method takes inputs and outputs the if the topic creation was successful.
  def create
    @project_topic = ProjectTopic.new(project_topic_params)
    @assignment = Assignment.find(params[:project_topic][:assignment_id])
    @project_topic.micropayment = params[:micropayment] if @assignment.microtask?
    if @project_topic.save
      render json: { message: "The topic: \"#{@project_topic.topic_name}\" has been created successfully. " }, status: :created
    else
      render json: { message: @project_topic.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /project_topics/1
  # updates parameters present in project_topic_params.
  def update
    if @project_topic.update(project_topic_params)
      render json: { message: "The topic: \"#{@project_topic.topic_name}\" has been updated successfully. " }, status: 200
    else
      render json: @project_topic.errors, status: :unprocessable_entity
    end
  end

  # GET /project_topics/:id
  # Show a ProjectTopic by ID
  def show
    render json: @project_topic, status: :ok
  end

# DELETE /project_topics
# Deletes one or more project topics associated with an assignment.
# If `assignment_id` or `topic_ids` are missing, appropriate validations are handled.
# Deletes the topics and returns a success message if successful or error messages otherwise.
  def destroy
    # Check if the assignment ID is provided
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    # Determine which topics to delete based on the provided parameters
    elsif params[:topic_ids].nil?
      # If no specific topic IDs are provided, fetch all topics for the assignment
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id])
    else
      # Fetch the specified topics for the assignment
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
    end

    # Attempt to delete the topics and return the appropriate response
    if @project_topics.each(&:delete)
      render json: { message: "The topic has been deleted successfully. " }, status: :no_content
    else
      render json: @project_topic.errors, status: :unprocessable_entity
    end
  end

  private

  # Callback to set the @project_topic instance variable.
  # This method is executed before certain actions (via `before_action`) to load the project topic.
  # If the topic is not found, it raises an ActiveRecord::RecordNotFound exception.
  def set_project_topic
    @project_topic = ProjectTopic.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def project_topic_params
    params.require(:project_topic).permit(:topic_identifier, :category, :topic_name, :max_choosers, :assignment_id)
  end
end
