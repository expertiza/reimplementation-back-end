class ProjectTopicsController < ApplicationController
  before_action :set_project_topic, only: %i[ show update ]

  # GET /project_topics?assignment_id=&topic_ids[]=
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
    # render json: {message: 'All selected topics have been loaded successfully.', project_topics: @stopics}, status: 200
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
      # undo_link "The topic: \"#{@project_topic.topic_name}\" has been created successfully. "
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

  # Show a ProjectTopic by ID
  def show
    render json: @project_topic, status: :ok
  end

  # Similar to index method, this method destroys ProjectTopics by two query parameters
  # assignment_id is compulsory.
  # topic_ids[] is optional
  def destroy
    # render json: {message: @sign_up_topic}
    # filters topics based on assignment id (required) and topic identifiers (optional)
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].nil?
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id])
      # render json: @project_topics, status: :ok
    else
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
      # render json: @project_topics, status: :ok
    end

    if @project_topics.each(&:delete)
      render json: { message: "The topic has been deleted successfully. " }, status: :no_content
    else
      render json: @project_topic.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project_topic
    @project_topic = ProjectTopic.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def project_topic_params
    params.require(:project_topic).permit(:topic_identifier, :category, :topic_name, :max_choosers, :assignment_id)
  end
end
