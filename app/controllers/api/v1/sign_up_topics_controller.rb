class Api::V1::SignUpTopicsController < ApplicationController
  before_action :set_sign_up_topic, only: %i[ show update destroy ]
  #runs
  before_action :load_all_selected_topics, only: [:delete_all_selected_topics]
  # GET /sign_up_topics
  def index
    @sign_up_topics = SignUpTopic.all
    render json: @sign_up_topics
  end

  # GET /sign_up_topics/1
  def show
    render json: @sign_up_topic
  end

  # POST /sign_up_topics
  # The create method allows the instructor to create a new topic
  # params[:sign_up_topic][:topic_identifier] follows a json format
  # The method takes inputs and outputs the if the topic creation was sucessfull.
  def create
      @sign_up_topic = SignUpTopic.new
      @sign_up_topic.topic_identifier = params[:sign_up_topic][:topic_identifier]
      @sign_up_topic.topic_name = params[:sign_up_topic][:topic_name]
      @sign_up_topic.max_choosers = params[:sign_up_topic][:max_choosers]
      @sign_up_topic.category = params[:sign_up_topic][:category]
      @sign_up_topic.assignment_id = params[:sign_up_topic][:assignment_id]
      @assignment = Assignment.find(params[:sign_up_topic][:assignment_id])
      @sign_up_topic.micropayment = params[:sign_up_topic][:micropayment] if @assignment.microtask?
      if @sign_up_topic.save
        #undo_link "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "
        render json: {message: "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "}, status: :created
      else
        render json: {message: @sign_up_topic.errors}, status: :unprocessable_entity
      end

  end

  # PATCH/PUT /sign_up_topics/1
  # the update function takes inputs as parameters which are similar to the create functionality, and the updated
  # parameter is then replaced in the data base. For example, a name can be inputted differently
  # with a unique ID to update a record.
  def update
    #@sign_up_topic = SignUpTopic.where(topic_name: params[:sign_up_topic][:topic_name], assignment_id: params[:sign_up_topic][:assignment_id]).first
    if @sign_up_topic.update(sign_up_topic_params)
      render json: {message: "The topic: \"#{@sign_up_topic.topic_name}\" has been updated successfully. "}, status: :created
    else
      render json: @sign_up_topic.errors, status: :unprocessable_entity
    end
  end

  # DELETE /sign_up_topics/1
  # The method selects and deletes the topic based on the id provided.
  def destroy
    @sign_up_topic.destroy
  end

  #the method loads all the selected topics
  def load_all_selected_topics
    @stopics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
    render json: {message: 'All selected topics have been loaded successfully.'}, status: 200
  end
  #this method deletes all selected topics
  def delete_all_selected_topics
    load_all_selected_topics
    @stopics.each(&:destroy)
    render json: {message: 'All selected topics have been deleted successfully.'}, status: 200
  end

  # This deletes all topics for the given assignment
  def delete_all_topics_for_assignment
    topics = SignUpTopic.where(assignment_id: params[:assignment_id])
    topics.each(&:destroy)
    render json: {message: 'All topics have been deleted successfully.'}, status: 200
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
