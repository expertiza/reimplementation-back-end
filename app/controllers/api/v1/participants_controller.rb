class Api::V1::ParticipantsController < ApplicationController
  include ParticipantsHelper
  # autocomplete :user, :name
  def index
    participants = Participant.all
    render json: participants
  end
  # ************************************************************
  #keeping this commented as to test
  # def action_allowed?
  #   if %w[change_handle update_duties].include? params[:action]
  #     current_user_has_student_privileges?
  #   else
  #     current_user_has_ta_privileges?
  #   end

  # end
  # ************************************************************
  #redundant by may be required later
  # def action_allowed?
  #   has_required_role?('Teaching Assistant')
  # end
  # ************************************************************

  def create
    @participant = Participant.new(participant_params)
    if @participant.save
      render json: @participant, status: :created
    else
      render json: { errors: @participant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  before_action :set_participant, only: [:show, :update, :destroy]

  # GET /api/v1/participants/:id
  def show
    render json: @participant
  end

  #getting the user by user_index and retrive and how on swagger ui
  def user_index
    participants = Participant.where(user_id: params[:user_id])
    render json: participants, status: :ok
  end

  #updating the participant by request body of  example { "can_submit": true, "can_review": true}
  def update
    if @participant.update(participant_params)
      render json: @participant, status: :ok
    else
      render json: { errors: @participant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  #destroying the user by the id of the specific user
  def destroy
    participant = Participant.find(params[:id])
    participant.destroy
    render json: { message: "Participant deleted successfully" }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Participant not found" }, status: :not_found
  end

  #finding partcipant by assignment id
  def assignment_index
    participants = Participant.where(assignment_id: params[:assignment_id])
    render json: participants, status: :ok
  end

  # def add
  #   handle = "#{user.name.parameterize}-#{SecureRandom.hex(2)}"

  #   assignment_id = params[:id]
  #   authorization = params[:authorization]
  #   user_name = params[:user][:name]
  
  #   user = User.find_by(name: user_name)
  #   return render json: { error: "User not found" }, status: :not_found if user.nil?
  
  #   assignment = Assignment.find(assignment_id)
  #   permissions = participant_permissions(authorization)
  
  #   participant = assignment.participants.create(
  #     user: user,
  #     handle: handle,
  #     can_submit: permissions[:can_submit],
  #     can_review: permissions[:can_review],
  #     can_take_quiz: permissions[:can_take_quiz],
  #     can_mentor: permissions[:can_mentor]
  #   )
  
  #   if participant.persisted?
  #     render json: participant, status: :created
  #   else
  #     render json: { errors: participant.errors.full_messages }, status: :unprocessable_entity
  #   end
  # end


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
    permissions = @context.get_permissions()
  
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

  # def participant_permissions(role)
  #   case role
  #   when 'Student'
  #     { can_submit: true, can_review: false, can_take_quiz: false, can_mentor: false }
  #   when 'Reviewer'
  #     { can_submit: false, can_review: true, can_take_quiz: false, can_mentor: false }
  #   when 'Teaching Assistant'
  #     { can_submit: false, can_review: true, can_take_quiz: false, can_mentor: true }
  #   when 'Mentor'
  #     { can_submit: false, can_review: false, can_take_quiz: false, can_mentor: true }
  #   else
  #     { can_submit: false, can_review: false, can_take_quiz: false, can_mentor: false }
  #   end
  # end

  def set_participant
    @participant = Participant.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Participant not found" }, status: 404
  end


  def participant_params
    params.require(:participant).permit(:user_id, :assignment_id)
  end

  
  
  # *****************************************************

  def controller_locale
    locale_for_student
  end

  #def list
  #  if Participant::PARTICIPANT_TYPES.include? params[:model]
  #    @root_node = Object.const_get(params[:model] + 'Node').find_by(node_object_id: params[:id])
  #    @parent = Object.const_get(params[:model]).find(params[:id])
  #  end
  #  begin
  #    @participants = @parent.participants
  #    @model = params[:model]
  #    @authorization = params[:authorization]
  #  rescue StandardError
  #    flash[:error] = $ERROR_INFO
  #  end
  #send

  # def add
  #   curr_object = Object.const_get(params[:model]).find(params[:id]) if Participant::PARTICIPANT_TYPES.include? params[:model]
  #   begin
  #     permissions = participant_permissions(params[:authorization])
  #     can_submit = permissions[:can_submit]
  #     can_review = permissions[:can_review]
  #     can_take_quiz = permissions[:can_take_quiz]
  #     #E2351 - add corresponding duty fill from permissions
  #     can_mentor = permissions[:can_mentor]
  #     if curr_object.is_a?(Assignment)
  #       curr_object.add_participant(params[:user][:name], can_submit, can_review, can_take_quiz, can_mentor)
  #     elsif curr_object.is_a?(Course)
  #       curr_object.add_participant(params[:user][:name])
  #     end
  #     user = User.find_by(name: params[:user][:name])
  #     @model = params[:model]
  #     @participant = curr_object.participants.find_by(user_id: user.id)
  #     flash.now[:note] = "The user <b>#{params[:user][:name]}</b> has successfully been added."
  #   rescue StandardError
  #     url_for controller: 'users', action: 'new'
  #     flash.now[:error] = "The user <b>#{params[:user][:name]}</b> does not exist or has already been added."
  #   end
  #   render action: 'add.js.erb', layout: false
  # end

  # when you change the duties, changes the permissions based on the new duty you go to
  # def update_authorizations
  #   participant = Participant.find(params[:id])
  #   permissions = participant_permissions(params[:authorization])
  #   can_submit = permissions[:can_submit]
  #   can_review = permissions[:can_review]
  #   can_take_quiz = permissions[:can_take_quiz]
  #   can_mentor = permissions[:can_mentor]
  #   parent_id = participant.parent_id
  #   # Upon successfully updating the attributes based on user role, a flash message is displayed to the user after the
  #   # change in the database. This also gives the user the error message if the update fails.
  #   begin
  #     participant.update_attributes(can_submit: can_submit, can_review: can_review, can_take_quiz: can_take_quiz, can_mentor: can_mentor)
  #     flash[:success] = 'The role of the selected participants has been successfully updated.'
  #   rescue StandardError
  #     flash[:error] = 'The update action failed.'
  #   end
  #   redirect_to action: 'list', id: parent_id, model: participant.class.to_s.gsub('Participant', '')
  # end

  # # def destroy
  # #   participant = Participant.find(params[:id])
  # #   parent_id = participant.parent_id
  # #   begin
  # #     participant.destroy
  # #     flash[:note] = undo_link("The user \"#{participant.user.name}\" has been successfully removed as a participant.")
  # #   rescue StandardError
  # #     flash[:error] = 'This participant is on a team, or is assigned as a reviewer for someone’s work.'
  # #   end
  # #   redirect_to action: 'list', id: parent_id, model: participant.class.to_s.gsub('Participant', '')
  # # end

  # # Copies existing participants from a course down to an assignment
  # def inherit
  #   assignment = Assignment.find(params[:id])
  #   course = assignment.course
  #   @copied_participants = []
  #   if course
  #     participants = course.participants
  #     if !participants.empty?
  #       participants.each do |participant|
  #         new_participant = participant.copy(params[:id])
  #         @copied_participants.push new_participant if new_participant
  #       end
  #       # Only display undo link if copies of participants are created
  #       if !@copied_participants.empty?
  #         undo_link("The participants from \"#{course.name}\" have been successfully copied to this assignment. ")
  #       else
  #         flash[:note] = 'All course participants are already in this assignment'
  #       end
  #     else
  #       flash[:note] = 'No participants were found to inherit this assignment.'
  #     end
  #   else
  #     flash[:error] = 'No course was found for this assignment.'
  #   end
  #   redirect_to controller: 'participants', action: 'list', id: assignment.id, model: 'Assignment'
  # end

  # # Take all participants from an assignment and "bequeath" them to course as course_participants.
  # def bequeath_all
  #   @copied_participants = []
  #   assignment = Assignment.find(params[:id])
  #   if assignment.course
  #     course = assignment.course
  #     assignment.participants.each do |participant|
  #       new_participant = participant.copy_to_course(course.id)
  #       @copied_participants.push new_participant if new_participant
  #     end
  #     # only display undo link if copies of participants are created
  #     if !@copied_participants.empty?
  #       undo_link("All participants were successfully copied to \"#{course.name}\". ")
  #     else
  #       flash[:note] = 'All assignment participants are already part of the course'
  #     end
  #   else
  #     flash[:error] = 'This assignment is not associated with a course.'
  #   end
  #   redirect_to controller: 'participants', action: 'list', id: assignment.id, model: 'Assignment'
  # end

  # Allow participant to change handle for this assignment
  # If the participant parameters are available, update the participant
  # and redirect to the view_actions page
  def change_handle
    @participant = AssignmentParticipant.find(params[:id])
    return unless current_user_id?(@participant.user_id)

    unless params[:participant].nil?
      if !AssignmentParticipant.where(parent_id: @participant.parent_id, handle: params[:participant][:handle]).empty?
        ExpertizaLogger.error LoggerMessage.new(controller_name, @participant.name, "Handle #{params[:participant][:handle]} already in use", request)
        flash[:error] = "<b>The handle #{params[:participant][:handle]}</b> is already in use for this assignment. Please select a different one."
        redirect_to controller: 'participants', action: 'change_handle', id: @participant
      else
        @participant.update_attributes(participant_params)
        ExpertizaLogger.info LoggerMessage.new(controller_name, @participant.name, 'The change handle is saved successfully', request)
        redirect_to controller: 'student_task', action: 'view', id: @participant
      end
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
      flash[:error] = "\"#{name}\" was not removed from this assignment. Please ensure that \"#{name}\" is not a reviewer or metareviewer and try again."
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
    if @context.nil?
      @context = RoleContext.new
    end
    # Sets the assigned strategy for the context
    @context.set_strategy_by_role(role)
  end

  def participant_params
    params.require(:participant).permit(:can_submit, :can_review, :user_id, :parent_id, :submitted_at,
                                        :permission_granted, :penalty_accumulated, :grade, :type, :handle,
                                        :time_stamp, :digital_signature, :can_mentor, :can_take_quiz)
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
# ***************************************************************************************************
# class Api::V1::ParticipantsController < ApplicationController
#   before_action :set_participant, only: [:show, :update, :destroy, :update_authorization]

#   def index
#     participants = Participant.all
#     render json: participants, status: :ok
#   end

#   def show
#     render json: @participant, status: :ok
#   end

#   def create
#     participant = Participant.new(participant_params)
#     if participant.save
#       render json: participant, status: :created
#     else
#       render json: { errors: participant.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   def update
#     if @participant.update(participant_params)
#       render json: @participant, status: :ok
#     else
#       render json: { errors: @participant.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   def destroy
#     @participant.destroy
#     render json: { message: "Participant deleted successfully" }, status: :no_content
#   end

#   def user_index
#     participants = Participant.where(user_id: params[:user_id])
#     render json: participants, status: :ok
#   end

#   def assignment_index
#     participants = Participant.where(assignment_id: params[:assignment_id])
#     render json: participants, status: :ok
#   end

#   def add
#     user = User.find_by(name: params[:user][:name])
#     if user.nil?
#       render json: { error: "User not found" }, status: :not_found
#       return
#     end

#     assignment = Assignment.find(params[:id])
#     participant = assignment.participants.create(user: user)

#     if participant.persisted?
#       render json: participant, status: :created
#     else
#       render json: { errors: participant.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   def update_authorization
#     permissions = participant_permissions(params[:authorization])
#     if @participant.update(permissions)
#       render json: @participant, status: :ok
#     else
#       render json: { errors: @participant.errors.full_messages }, status: :unprocessable_entity
#     end
#   end

#   private

#   def set_participant
#     @participant = Participant.find_by(id: params[:id])
#     render json: { error: "Participant not found" }, status: :not_found if @participant.nil?
#   end

#   def participant_params
#     params.require(:participant).permit(:user_id, :assignment_id, :can_submit, :can_review, :can_take_quiz)
#   end
# end
