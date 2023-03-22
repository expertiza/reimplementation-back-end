# contains all functions related to management of the signup sheet for an assignment
# functions to add new topics to an assignment, edit properties of a particular topic, delete a topic, etc
# are included here

# A point to be taken into consideration is that :id (except when explicitly stated) here means topic id and not assignment id
# (this is referenced as :assignment id in the params has)
# The way it works is that assignments have their own id's, so do topics. A topic has a foreign key dependency on the assignment_id
# Hence each topic has a field called assignment_id which points which can be used to identify the assignment that this topic belongs
# to

class Api::V1::SignUpSheetController < ApplicationController

  #Work in progress
  def sign_up
    #needs dummy data.
    @assignment = AssignmentParticipant.find(params[:id]).assignment
    @user_id = session[:user].id
    # Always use team_id ACS
    # s = Signupsheet.new
    # Team lazy initialization: check whether the user already has a team for this assignment
    if SignUpSheet.signup_team(@assignment.id, @user_id, params[:topic_id]) == true
      render json: {message: "Sign up success" }, status: 200
    else
      render json: {message: "You've already signed up for a topic!" }, status: :unprocessable_entity
    end
  end

  #Work in progress
  def signup_as_instructor_action
    user = User.find_by(name: params[:username])
    if user.nil? # validate invalid user
      #flash[:error] = 'That student does not exist!'
      render json: {message: 'That student does not exist!'}, status: :unprocessable_entity
    else
      if AssignmentParticipant.exists? user_id: user.id, parent_id: params[:assignment_id]
        if SignUpSheet.signup_team(params[:assignment_id], user.id, params[:topic_id])
          #flash[:success] = 'You have successfully signed up the student for the topic!'
          #ExpertizaLogger.info LoggerMessage.new(controller_name, '', 'Instructor signed up student for topic: ' + params[:topic_id].to_s)
          render json: {message: 'You have successfully signed up the student for the topic!',log: {controller_name: controller_name, user_id: '', message: 'Instructor signed up student for topic: ' + params[:topic_id].to_s }}, status: :created
        else
          #flash[:error] = 'The student has already signed up for a topic!'
          #ExpertizaLogger.info LoggerMessage.new(controller_name, '', 'Instructor is signing up a student who already has a topic')
          render json: {message: 'The student has already signed up for a topic!',log: {controller_name: controller_name, user_id: '', message: 'Instructor is signing up a student who already has a topic' }}, status: :unprocessable_entity
        end
      else
        #flash[:error] = 'The student is not registered for the assignment!'
        #ExpertizaLogger.info LoggerMessage.new(controller_name, '', 'The student is not registered for the assignment: ' << user.id)
        render json: {message: 'The student is not registered for the assignment!',log: {controller_name: controller_name, user_id: '', message: 'The student is not registered for the assignment: ' << user.id }}, status: :unprocessable_entity
      end
    end
    #redirect_to controller: 'assignments', action: 'edit', id: params[:assignment_id]
  end

  #Work in progress
  # this function is used to delete a previous signup
  def delete_signup
    participant = AssignmentParticipant.find(params[:id])
    assignment = participant.assignment
    drop_topic_deadline = assignment.due_dates.find_by(deadline_type_id: 6)
    # A student who has already submitted work should not be allowed to drop his/her topic!
    # (A student/team has submitted if participant directory_num is non-null or submitted_hyperlinks is non-null.)
    # If there is no drop topic deadline, student can drop topic at any time (if all the submissions are deleted)
    # If there is a drop topic deadline, student cannot drop topic after this deadline.
    if !participant.team.submitted_files.empty? || !participant.team.hyperlinks.empty?
      #flash[:error] = 'You have already submitted your work, so you are not allowed to drop your topic.'
      #ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].id, 'Dropping topic for already submitted a work: ' + params[:topic_id].to_s)
      render json: {message: 'You have already submitted your work, so you are not allowed to drop your topic.',log: {controller_name: controller_name, user_id: session[:user].id, message: 'Dropping topic for already submitted a work: ' + params[:topic_id].to_s }}, status: :unprocessable_entity
    elsif !drop_topic_deadline.nil? && (Time.now > drop_topic_deadline.due_at)
      #flash[:error] = 'You cannot drop your topic after the drop topic deadline!'
      #ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].id, 'Dropping topic for ended work: ' + params[:topic_id].to_s)
      render json: {message: 'You cannot drop your topic after the drop topic deadline!' ,log: {controller_name: controller_name, user_id: session[:user].id, message: 'Dropping topic for ended work: ' + params[:topic_id].to_s }}, status: :unprocessable_entity
    else
      delete_signup_for_topic(assignment.id, params[:topic_id], session[:user].id)
      #flash[:success] = 'You have successfully dropped your topic!'
      #ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].id, 'Student has dropped the topic: ' + params[:topic_id].to_s)
      render json: {message: 'You have successfully dropped your topic!' ,log: {controller_name: controller_name, user_id: session[:user].id, message: 'Student has dropped the topic: ' + params[:topic_id].to_s}}, status: 200
    end
    #redirect_to action: 'list', id: params[:id]
  end

  #Work in progress
  def delete_signup_as_instructor
    # find participant using assignment using team and topic ids
    team = Team.find(params[:id])
    assignment = Assignment.find(team.parent_id)
    user = TeamsUser.find_by(team_id: team.id).user
    participant = AssignmentParticipant.find_by(user_id: user.id, parent_id: assignment.id)
    drop_topic_deadline = assignment.due_dates.find_by(deadline_type_id: 6)
    if !participant.team.submitted_files.empty? || !participant.team.hyperlinks.empty?
      #flash[:error] = 'The student has already submitted their work, so you are not allowed to remove them.'
      #ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].id, 'Drop failed for already submitted work: ' + params[:topic_id].to_s)
      render json: {message: 'The student has already submitted their work, so you are not allowed to remove them.' ,log: {controller_name: controller_name, user_id: session[:user].id, message: 'Drop failed for already submitted work: ' + params[:topic_id].to_s }}, status: :unprocessable_entity
    elsif !drop_topic_deadline.nil? && (Time.now > drop_topic_deadline.due_at)
      #flash[:error] = 'You cannot drop a student after the drop topic deadline!'
      #ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].id, 'Drop failed for ended work: ' + params[:topic_id].to_s)
      render json: {message: 'You cannot drop a student after the drop topic deadline!' ,log: {controller_name: controller_name, user_id: session[:user].id, message: 'Drop failed for ended work: ' + params[:topic_id].to_s }}, status: :unprocessable_entity
    else
      delete_signup_for_topic(assignment.id, params[:topic_id], participant.user_id)
      #flash[:success] = 'You have successfully dropped the student from the topic!'
      #ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].id, 'Student has been dropped from the topic: ' + params[:topic_id].to_s)
      render json: {message: 'You have successfully dropped the student from the topic!' ,log: {controller_name: controller_name, user_id: session[:user].id, message: 'Student has been dropped from the topic: ' + params[:topic_id].to_s}}, status: 200
    end
    #redirect_to controller: 'assignments', action: 'edit', id: assignment.id
  end

  private

end