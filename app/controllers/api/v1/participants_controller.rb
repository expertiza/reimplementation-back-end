class Api::V1::ParticipantsController < ApplicationController
  include ParticipantsHelper
  # autocomplete :user, :name
  def index
    participants = Participant.all
    render json: participants
  end

  def create
    @participant = Participant.new(participant_params)
    if @participant.save
      render json: @participant, status: :created
    else
      render json: { errors: @participant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  before_action :set_participant, only: %i[show update destroy]

  # GET /api/v1/participants/:id
  def show
    render json: @participant
  end

  # getting the user by user_index and retrive and how on swagger ui
  def user_index
    participants = Participant.where(user_id: params[:user_id])
    if participants.empty?
      #render json: participants, status: :not_found 
      render json: { error: "User not found" }, status: :not_found
    else
      render json: participants, status: :ok 
    end
  end

  # updating the participant by request body of  example { "can_submit": true, "can_review": true}
  def update
    if @participant.update(participant_params)
      render json: @participant, status: :ok
    else
      render json: { errors: @participant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # destroying the user by the id of the specific user
  def destroy
    participant = Participant.find(params[:id])
    participant.destroy
    render json: { message: "Participant deleted successfully" }, status: :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Participant Not Found" }, status: :not_found
  end

  # finding partcipant by assignment id
  def assignment_index
    participants = Participant.where(assignment_id: params[:assignment_id])
    #render json: participants, status: :ok
    if participants.empty?
      #render json: participants, status: :not_found 
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: participants, status: :ok 
    end
  end

  #adding a participant with authorization

  def add
    assignment = Assignment.find(params[:id])
    user = User.find_or_create_by(user_params) # 👈 You were probably missing this line

    # Now you can safely use `user` below
    handle = "#{user.name.parameterize}-#{SecureRandom.hex(2)}"

    # Updates RoleContext with appropriate strategy for user
    update_context(params[:authorization])
    permissions = @context.get_permissions

    participant = assignment.participants.create!(
      user: user,
      handle: handle,
      can_submit: permissions[:can_submit],
      can_review: permissions[:can_review],
      can_take_quiz: permissions[:can_take_quiz],
      can_mentor: permissions[:can_mentor]
    )

    render json: participant, status: :created
  end

  # Updating authorization of the participants
  def update_authorization
    # Get participant via ID
    participant = Participant.find(params[:id])

    # Updates the RoleContext with the necessary strategy and obtains permissions
    update_context(params[:authorization])
    permissions = @context.get_permissions

    # Updates the participant's permissions to match
    participant.update!(
      can_submit: permissions[:can_submit],
      can_review: permissions[:can_review],
      can_take_quiz: permissions[:can_take_quiz],
      can_mentor: permissions[:can_mentor]
    )

    render json: participant, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:name)
  end

  def set_participant
    @participant = Participant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Participant Not Found" }, status: 404

  end

  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id)
  end

  def controller_locale
    locale_for_student
  end

  # Allow participant to change handle for this assignment
  # If the participant parameters are available, update the participant
  # and redirect to the view_actions page
  def change_handle
    @participant = AssignmentParticipant.find(params[:id])
    return unless current_user_id?(@participant.user_id)

    return if params[:participant].nil?

    if !AssignmentParticipant.where(parent_id: @participant.parent_id, handle: params[:participant][:handle]).empty?
      ExpertizaLogger.error LoggerMessage.new(controller_name, @participant.name,
                                              "Handle #{params[:participant][:handle]} already in use", request)
      flash[:error] =
        "<b>The handle #{params[:participant][:handle]}</b> is already in use for this assignment. Please select a different one."
      redirect_to controller: 'participants', action: 'change_handle', id: @participant
    else
      @participant.update_attributes(participant_params)
      ExpertizaLogger.info LoggerMessage.new(controller_name, @participant.name,
                                             'The change handle is saved successfully', request)
      redirect_to controller: 'student_task', action: 'view', id: @participant
    end
  end

  # Deletes participants from an assignment
  def delete
    contributor = AssignmentParticipant.find(params[:id])
    name = contributor.name
    assignment_id = contributor.assignment
    begin
      contributor.destroy
      flash[:note] = "\"#{name}\" is no longer a participant in this assignment."
    rescue StandardError
      flash[:error] =
        "\"#{name}\" was not removed from this assignment. Please ensure that \"#{name}\" is not a reviewer or metareviewer and try again."
    end
    redirect_to controller: 'review_mapping', action: 'list_mappings', id: assignment_id
  end

  # A ‘copyright grant’ means the author has given permission to the instructor to use the work outside the course.
  # This is incompletely implemented, but the values in the last column in http://expertiza.ncsu.edu/student_task/list are sourced from here.
  def view_copyright_grants
    assignment_id = params[:id]
    assignment = Assignment.find(assignment_id)
    @assignment_name = assignment.name
    @has_topics = false
    @teams_info = []
    teams = Team.where(parent_id: assignment_id)
    teams.each do |team|
      team_info = {}
      team_info[:name] = team.name(session[:ip])
      users = []
      team.users { |team_user| users.append(get_user_info(team_user, assignment)) }
      team_info[:users] = users
      @has_topics = get_signup_topics_for_assignment(assignment_id, team_info, team.id)
      team_without_topic = SignedUpTeam.where('team_id = ?', team.id).none?
      next if @has_topics && team_without_topic

      @teams_info.append(team_info)
    end
    @teams_info = @teams_info.sort_by { |hashmap| [hashmap[:topic_id] ? 0 : 1, hashmap[:topic_id] || 0] }
  end

  private

  # Private method that ensures that the context is initialized and updates
  # The strategy being used by the context given the
  def update_context(role)
    # Creates new RoleContext if one does not already exist
    @context = RoleContext.new if @context.nil?
    # Sets the assigned strategy for the context
    @context.set_strategy_by_role(role)
  end

  # Get the user info from the team user
  def get_user_info(team_user, assignment)
    user = {}
    user[:name] = team_user.name
    user[:fullname] = team_user.fullname
    # set by default
    permission_granted = false
    assignment.participants.each do |participant|
      permission_granted = participant.permission_granted? if team_user.id == participant.user.id
    end
    # If permission is granted, set the publisting rights string
    user[:pub_rights] = permission_granted ? 'Granted' : 'Denied'
    user[:verified] = false
    user
  end

  # Get the signup topics for the assignment
  def get_signup_topics_for_assignment(assignment_id, team_info, team_id)
    signup_topics = SignUpTopic.where('assignment_id = ?', assignment_id)
    if signup_topics.any?
      has_topics = true
      signup_topics.each do |signup_topic|
        signup_topic.signed_up_teams.each do |signed_up_team|
          if signed_up_team.team_id == team_id
            team_info[:topic_name] = signup_topic.topic_name
            team_info[:topic_id] = signup_topic.topic_identifier.to_i
          end
        end
      end
    end
    has_topics
  end
end
