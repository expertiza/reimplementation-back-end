class Api::V1::SignUpTopicsController < ApplicationController
  before_action :set_sign_up_topic, only: %i[ show update destroy ]

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
  def create
    #need data for test to pass
    #render json: {message: "The topic: has been created successfully. "}, status: :created
    #topic = ['a',1]
    topic = SignUpTopic.where(topic_name: params[:sign_up_topic][:topic_name], assignment_id: params[:sign_up_topic][:assignment_id]).first
    if topic.nil?
      @sign_up_topic = SignUpTopic.new #(sign_up_topic_params)
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
        #redirect_to edit_assignment_path(@sign_up_topic.assignment_id) + '#tabs-2'
      else
        render json: {message: @sign_up_topic.errors}, status: :unprocessable_entity
      end
    else
      topic.topic_identifier = params[:sign_up_topic][:topic_identifier]
      #update_max_choosers(topic)
      topic.category = params[:sign_up_topic][:category]
      # topic.assignment_id = params[:id]
      topic.save
      render json: {message: "The topic: \"#{@sign_up_topic.topic_name}\" has been created previously and was updated successfully. "}, status: :created
    end
  end

  # PATCH/PUT /sign_up_topics/1
  def update
    if @sign_up_topic.update(sign_up_topic_params)
      render json: @sign_up_topic
    else
      render json: @sign_up_topic.errors, status: :unprocessable_entity
    end
  end

  # DELETE /sign_up_topics/1
  def destroy
    @sign_up_topic.destroy
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
