class ProjectTopicsController < ApplicationController
  before_action :set_project_topic, only: %i[ show update ]

  # GET /project_topics?assignment_id=&topic_ids[]=
  def index
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    else
      @project_topics = ProjectTopic.find_by_assignment_and_topic_ids(params[:assignment_id], params[:topic_ids])
      render json: @project_topics.map(&:to_json_with_computed_data), status: :ok
    end
  end

  # POST /project_topics
  def create
    result = ProjectTopic.create_topic_with_assignment(
      project_topic_params, 
      params[:project_topic][:assignment_id], 
      params[:micropayment]
    )
    
    if result[:success]
      render json: { message: result[:message] }, status: :created
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /project_topics/1
  def update
    result = @project_topic.update_topic(project_topic_params)
    
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { message: result[:message] }, status: :unprocessable_entity
    end
  end

  # Show a ProjectTopic by ID
  def show
    render json: @project_topic, status: :ok
  end

  # Destroy ProjectTopics by assignment_id and optional topic_ids
  def destroy
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    else
      result = ProjectTopic.delete_by_assignment_and_topic_ids(params[:assignment_id], params[:topic_ids])
      
      if result[:success]
        render json: { message: result[:message] }, status: :no_content
      else
        render json: { message: result[:message] }, status: :unprocessable_entity
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_project_topic
    @project_topic = ProjectTopic.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def project_topic_params
    params.require(:project_topic).permit(:topic_identifier, :category, :topic_name, :max_choosers, :assignment_id, :description, :link)
  end
end
