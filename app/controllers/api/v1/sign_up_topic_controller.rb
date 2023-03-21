# contains all functions related to management of the signup sheet for an assignment
# functions to add new topics to an assignment, edit properties of a particular topic, delete a topic, etc
# are included here

# A point to be taken into consideration is that :id (except when explicitly stated) here means topic id and not assignment id
# (this is referenced as :assignment id in the params has)
# The way it works is that assignments have their own id's, so do topics. A topic has a foreign key dependency on the assignment_id
# Hence each topic has a field called assignment_id which points which can be used to identify the assignment that this topic belongs
# to

class Api::V1::SignUpTopicController < ApplicationController

  def index
  end

  # This method is used to create signup topics
  # In this code params[:id] is the assignment id and not topic id. The intuition is
  # that assignment id will virtually be the signup sheet id as well as we have assumed
  # that every assignment will have only one signup sheet
  def create_topic
    #need data for test to pass
    #render json: {message: "The topic: has been created successfully. "}, status: :created
    topic = SignUpTopic.where(topic_name: params[:topic][:topic_name], assignment_id: params[:id]).first
    if topic.nil?
      @sign_up_topic = SignUpTopic.new
      @sign_up_topic.topic_identifier = params[:topic][:topic_identifier]
      @sign_up_topic.topic_name = params[:topic][:topic_name]
      @sign_up_topic.max_choosers = params[:topic][:max_choosers]
      @sign_up_topic.category = params[:topic][:category]
      @sign_up_topic.assignment_id = params[:id]
      @assignment = Assignment.find(params[:id])
      @sign_up_topic.micropayment = params[:topic][:micropayment] if @assignment.microtask?
      if @sign_up_topic.save
        #undo_link "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "
        render json: {message: "The topic: \"#{@sign_up_topic.topic_name}\" has been created successfully. "}, status: :created
        #redirect_to edit_assignment_path(@sign_up_topic.assignment_id) + '#tabs-2'
      else
        render action: 'new', id: params[:id]
      end
    else
      topic.topic_identifier = params[:topic][:topic_identifier]
      update_max_choosers(topic)
      topic.category = params[:topic][:category]
      # topic.assignment_id = params[:id]
      topic.save
      redirect_to_sign_up(params[:id])
    end
  end

  # updates the database tables to reflect the new values for the assignment. Used in conjunction with edit
  def update_topic
    @topic = SignUpTopic.find(params[:id])
    if @topic
      @topic.topic_identifier = params[:topic][:topic_identifier]
      update_max_choosers @topic
      @topic.category = params[:topic][:category]
      @topic.topic_name = params[:topic][:topic_name]
      @topic.micropayment = params[:topic][:micropayment]
      @topic.description = params[:topic][:description]
      @topic.link = params[:topic][:link]
      @topic.save
      undo_link("The topic: \"#{@topic.topic_name}\" has been successfully updated. ")
    else
      render json: :error, status: 'The topic could not be updated.'
    end
    #orrectly changing the redirection url to topics tab in edit assignment view.
    render json: @topic, status: :updated
    #redirect_to edit_assignment_path(params[:assignment_id]) + '#tabs-2'
  end


  # This method is used to delete signup topics
  # Renaming delete method to destroy for rails 4 compatible
  def destroy_topic
    @topic = SignUpTopic.find(params[:id])
    assignment = Assignment.find(params[:assignment_id])
    if @topic
      @topic.destroy
      undo_link("The topic: \"#{@topic.topic_name}\" has been successfully deleted. ")
      render json: { message: "The topic: \"#{@topic.topic_name}\" has been successfully deleted. " },  status: "The topic: \"#{@topic.topic_name}\" has been successfully deleted. "
    else
      render json: @topic.error, status: 'The topic could not be deleted.'
    end
    #Removed redirect_to as Rails API
  end

  # This deletes all topics for the given assignment
  def delete_all_topics_for_assignment
    topics = SignUpTopic.where(assignment_id: params[:assignment_id])
    topics.each(&:destroy)
    render json: {message: 'All topics have been deleted successfully.'}, status: 200
  end

  # This loads all selected topics based on all the topic identifiers selected for that assignment into stopics variable
  def load_all_selected_topics
    @stopics = SignUpTopic.where(assignment_id: params[:assignment_id], topic_identifier: params[:topic_ids])
    #render json: {message: 'All selected topics have been deleted successfully.'}, status: 200
  end

  # This deletes all selected topics for the given assignment
  def delete_all_selected_topics
    load_all_selected_topics
    @stopics.each(&:destroy)
    render json: {message: 'All selected topics have been deleted successfully.'}, status: 200
  end

  # This displays a page that lists all the available topics for an assignment.
  # Contains links that let an admin or Instructor edit, delete, view enrolled/waitlisted members for each topic
  # Also contains links to delete topics and modify the deadlines for individual topics. Staggered means that different topics can have different deadlines.
  def add_signup_topics
    load_add_signup_topics(params[:id])
    render json: SignUpSheet.add_signup_topic(params[:id]), status: 200
  end

  # retrieves all the data associated with the given assignment. Includes all topics,
  def load_add_signup_topics(assignment_id)
    @id = assignment_id
    @sign_up_topics = SignUpTopic.where('assignment_id = ?', assignment_id)
    @slots_filled = SignUpTopic.find_slots_filled(assignment_id)
    @slots_waitlisted = SignUpTopic.find_slots_waitlisted(assignment_id)

    @assignment = Assignment.find(assignment_id)
    # ACS Removed the if condition (and corresponding else) which differentiate assignments as team and individual assignments
    # to treat all assignments as team assignments
    # Though called participants, @participants are actually records in signed_up_teams table, which
    # is a mapping table between teams and topics (waitlisted recorded are also counted)
    @participants = SignedUpTeam.find_team_participants(assignment_id, session[:ip])
  end



  private

  def update_max_choosers(topic)
    # While saving the max choosers you should be careful; if there are users who have signed up for this particular
    # topic and are on waitlist, then they have to be converted to confirmed topic based on the availability. But if
    # there are choosers already and if there is an attempt to decrease the max choosers, as of now I am not allowing
    # it.
    if SignedUpTeam.find_by(topic_id: topic.id).nil? || topic.max_choosers == params[:topic][:max_choosers]
      topic.max_choosers = params[:topic][:max_choosers]
    elsif topic.max_choosers.to_i < params[:topic][:max_choosers].to_i
      topic.update_waitlisted_users params[:topic][:max_choosers]
      topic.max_choosers = params[:topic][:max_choosers]
    else
      render json: {message: 'The value of the maximum number of choosers can only be increased! No change has been made to maximum choosers.'}, status: :unprocessable_entity
    end
  end

end