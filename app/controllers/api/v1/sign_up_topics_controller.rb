class Api::V1::SignUpTopicsController < ApplicationController
  before_action :set_sign_up_topic, only: %i[ show update destroy ]

  # GET /sign_up_topics
  def index
    @sign_up_topics = SignUpTopic.all
    render json: @sign_up_topics
  end

  # POST /sign_up_topics
  # The create method allows the instructor to create a new topic
  # params[:sign_up_topic][:topic_identifier] follows a json format
  # The method takes inputs and outputs the if the topic creation was sucessfull.
  def create
      @sign_up_topic = SignUpTopic.new(sign_up_topic_params)
      @assignment = Assignment.find(params[:sign_up_topic][:assignment_id])
      @sign_up_topic.micropayment = params[:micropayment] if @assignment.microtask?
      if @sign_up_topic.save
        #undo_link "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "
        render json: {message: "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "}, status: :created
      else
        render json: {message: @sign_up_topic.errors}, status: :unprocessable_entity
      end

  end

  # PATCH/PUT /sign_up_topics/1
  # updates parameters present in sign_up_topic_params.
  def update
    if @sign_up_topic.update(sign_up_topic_params)
      render json: {message: "The topic: \"#{@sign_up_topic.topic_name}\" has been updated successfully. "}, status: 200
    else
      render json: @sign_up_topic.errors, status: :unprocessable_entity
    end
  end

  # DELETE /sign_up_topics/1
  # The method selects and deletes the topic based on the id provided.
  def destroy
    if @sign_up_topic.destroy
      render json: {message: "The topic has been deleted successfully. "}, status: 200
    else
      render json: @sign_up_topic.errors, status: :unprocessable_entity
    end
  end

  # filters topics based on assignment id (required) and topic identifiers (optional)
  # follows a restful API and is called on the GET call.
  def filter
    if params[:assignment_id].nil?
      render json: {message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].nil?
      @stopics = SignUpTopic.where(assignment_id: params[:assignment_id])
    else
      @stopics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
    end
    render json: {message: 'All selected topics have been loaded successfully.', sign_up_topics: @stopics}, status: 200
  end

  # this method deletes all selected topics (follows a restful approach )
  # the method below is called when a delete call is made to filter
  # assignment id IN COMBINATION with the topic id DELETES the topics
  def delete_filter
    #filters topics based on assignment id (required) and topic identifiers (optional)
    if params[:assignment_id].nil?
      render json: {message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].empty?
      @stopics = SignUpTopic.where(assignment_id: params[:assignment_id])
    else
      @stopics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
    end
    @stopics.each(&:delete)
    render json: {message: 'All selected topics have been deleted successfully.', sign_up_topics: @stopics }, status: 200
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sign_up_topic
      @sign_up_topic = SignUpTopic.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sign_up_topic_params
      params.require(:sign_up_topic).permit(:topic_identifier, :category, :topic_name, :max_choosers, :assignment_id)
    end
end
