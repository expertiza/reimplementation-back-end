class ProjectTopicsController < ApplicationController
  before_action :set_project_topic, only: %i[ show update ]

  # Anyone signed in may view topics; changing them requires managing the assignment.
  def action_allowed?
    case action_name
    when 'create'
      may_change_topics_of?(params.dig(:project_topic, :assignment_id))
    when 'destroy'
      may_change_topics_of?(params[:assignment_id])
    when 'update'
      may_update_topic?
    else
      true
    end
  end

  # GET /project_topics?assignment_id=&topic_ids[]=
  # Retrieve ProjectTopics by two query parameters - assignment_id (compulsory) and an array of topic_ids (optional)
  def index
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].nil?
      # Ordered explicitly: the unique index on (assignment_id, topic_identifier)
      # makes database return rows in topic_identifier order rather than insertion order.
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id]).order(:id)
      render json: @project_topics, status: :ok
    else
      @project_topics = ProjectTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids]).order(:id)
      render json: @project_topics, status: :ok
    end
    # render json: {message: 'All selected topics have been loaded successfully.', project_topics: @stopics}, status: 200
  end

  # POST /project_topics
  # The create method allows the instructor to create a new topic
  # params[:project_topic][:topic_identifier] follows a json format
  # The method takes inputs and outputs the if the topic creation was successful.
  def create
    project_topic = ProjectTopic.new(project_topic_params)

    assignment = Assignment.find_by(id: project_topic.assignment_id)

    if assignment&.microtask?
      project_topic.micropayment = params[:project_topic][:micropayment]
    end
    if project_topic.save
      render json: { message: "The topic: \"#{project_topic.topic_name}\" has been created successfully." }, status: :created
    else
      render json: { message: project_topic.errors }, status: :unprocessable_entity
    end
  # Catches a race: two requests can both pass the model's uniqueness check
  # before either one's INSERT runs, so the database's unique index rejects
  # the second INSERT. Respond with the same 422 "already taken" error the
  # validation would give, instead of letting that DB error become a 500.
  rescue ActiveRecord::RecordNotUnique
    render json: { message: { topic_identifier: ["has already been taken"] } }, status: :unprocessable_entity
  rescue => e
      render json: { error: "Unexpected error: #{e.message}" }, status: :internal_server_error
  end

  # PATCH/PUT /project_topics/1
  # updates parameters present in project_topic_params.
  def update
    assignment = Assignment.find_by(id: @project_topic.assignment_id)

    if assignment&.microtask?
      @project_topic.micropayment = params[:project_topic][:micropayment]
    end

    if @project_topic.update(project_topic_params)
      render json: { message: "The topic: \"#{@project_topic.topic_name}\" has been updated successfully." }, status: 200
    else
      render json:{ message: @project_topic.errors }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { message: { topic_identifier: ["has already been taken"] } }, status: :unprocessable_entity
  end

  # Show a ProjectTopic by ID
  def show
    render json: @project_topic, status: :ok
  end

  # Similar to index method, this method destroys ProjectTopics by two query parameters
  # assignment_id is compulsory.
  # topic_ids[] is optional
  def destroy
    # filters topics based on assignment id (required) and topic identifiers (optional)
    if params[:assignment_id].blank?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
      return
    elsif params[:topic_ids].blank?
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

  # A topic being moved needs rights on both the current and the destination assignment.
  def may_update_topic?
    return false unless current_user_has_ta_privileges?

    topic = ProjectTopic.find_by(id: params[:id])
    return true unless topic # set_project_topic answers 404
    return false unless current_user_can_manage?(topic.assignment)

    destination = params[:project_topic].is_a?(ActionController::Parameters) && params[:project_topic][:assignment_id]
    !destination || may_change_topics_of?(destination)
  end

  # A blank or unknown id passes for teaching staff because the action itself
  # rejects it (422) or matches no topics. A list is refused: it could pair a
  # managed assignment with someone else's in the same delete.
  def may_change_topics_of?(assignment_id)
    return false unless current_user_has_ta_privileges?
    return true if assignment_id.blank?
    return false unless assignment_id.is_a?(String) || assignment_id.is_a?(Integer)

    assignment = Assignment.find_by(id: assignment_id)
    assignment.nil? || current_user_can_manage?(assignment)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_project_topic
    @project_topic = ProjectTopic.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def project_topic_params
    params.require(:project_topic).permit(:topic_identifier, :category, :topic_name, :max_choosers, :assignment_id, :description, :link)
  end
end
