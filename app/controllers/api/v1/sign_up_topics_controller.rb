class Api::V1::SignUpTopicsController < ApplicationController
  before_action :set_sign_up_topic, only: %i[ show update destroy ]

  # GET /sign_up_topics
  # def index
  #   @sign_up_topics = SignUpTopic.all
  #   render json: @sign_up_topics
  # end

  # GET /sign_up_topics
  # This modified index method allows filtering by assignment_id and topic_identifier
  # def index
  #   if params[:assignment_id].nil?
  #     render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
  #   else
  #     if params[:topic_identifier].nil?
  #       @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id])
  #     else
  #       @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_identifier])
  #     end
  #     render json: { message: 'All selected topics have been loaded successfully.', sign_up_topics: @sign_up_topics }, status: 200
  #   end
  # end

  # def index
  #   if params[:assignment_id].nil?
  #     render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
  #   else
  #     if params[:topic_identifier].nil?
  #       @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id])
  #       message = "All sign-up topics for assignment #{params[:assignment_id]} have been loaded successfully."
  #     else
  #       @sign_up_topics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_identifier])
  #       message = "Sign-up topic for assignment #{params[:assignment_id]} with identifier #{params[:topic_identifier]} has been loaded successfully."
  #     end
  #     render json: { message: message, sign_up_topics: @sign_up_topics }, status: :ok
  #   end
  # end

  def index
    if params[:assignment_id].nil?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    else
      @sign_up_topics = find_sign_up_topics_by_params
      render json: { message: index_message, sign_up_topics: @sign_up_topics }, status: index_status
    end
  end
  
  def destroy
    assignment_id = params[:assignment_id]
    topic_ids = params[:topic_ids]

    if assignment_id.blank?
      render json: { message: 'Assignment ID is required!' }, status: :unprocessable_entity
    else
      sign_up_topics = topic_ids.present? ? SignUpTopic.where(assignment_id:, topic_identifier: topic_ids) : SignUpTopic.where(assignment_id:)

      if sign_up_topics.empty?
        render json: { message: 'No sign-up topics found for the specified criteria.' }, status: :not_found
      else
        sign_up_topics.destroy_all
        render json: { message: 'All selected topics have been deleted successfully.' }, status: :ok
      end
    end
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
  # def destroy
  #   if @sign_up_topic.destroy
  #     render json: {message: "The topic has been deleted successfully. "}, status: 200
  #   else
  #     render json: @sign_up_topic.errors, status: :unprocessable_entity
  #   end
  # end

  # filters topics based on assignment id (required) and topic identifiers (optional)
  # follows a restful API and is called on the GET call.
  # def filter
  #   get_selected_topics
  #   render json: {message: 'All selected topics have been loaded successfully.', sign_up_topics: @stopics}, status: 200
  # end
  #
  # # this method deletes all selected topics (follows a restful approach )
  # # the method below is called when a delete call is made to filter
  # # assignment id IN COMBINATION with the topic id DELETES the topics
  # def delete_filter
  #   #filters topics based on assignment id (required) and topic identifiers (optional)
  #   get_selected_topics
  #   @stopics.each(&:delete)
  #   render json: {message: 'All selected topics have been deleted successfully.', sign_up_topics: @stopics }, status: 200
  # end

  private

  def index_status
    @sign_up_topics.present? ? :ok : :not_found
  end

  def find_sign_up_topics_by_params
    if params[:topic_identifier].nil?
      SignUpTopic.where(assignment_id: params[:assignment_id])
    else
      SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_identifier])
    end
  end

  def index_message
    if params[:topic_identifier].nil?
      "All sign-up topics for assignment #{params[:assignment_id]} have been loaded successfully."
    else
      "Sign-up topic with identifier '#{params[:topic_identifier]}' for assignment #{params[:assignment_id]} has been loaded successfully."
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_sign_up_topic
    @sign_up_topic = SignUpTopic.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def sign_up_topic_params
    params.require(:sign_up_topic).permit(:topic_identifier, :category, :topic_name, :max_choosers, :assignment_id)
  end

  def get_selected_topics
    if params[:assignment_id].nil?
      render json: {message: 'Assignment ID is required!' }, status: :unprocessable_entity
    elsif params[:topic_ids].nil?
      @stopics = SignUpTopic.where(assignment_id: params[:assignment_id])
    else
      @stopics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
    end
  end
end