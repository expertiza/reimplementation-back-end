class Api::V1::AssignmentsController < ApplicationController

  # GET /api/v1/assignments
  def index
    assignments = Assignment.all
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched all assignments.", request)
    render json: assignments
  end

  # GET /api/v1/assignments/:id
  def show
    assignment = Assignment.find(params[:id])
    # For now, just logging success - if error checking is added in the future, please add a log message for that with
    # ExpertizaLogger.error
    ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched assignment with ID: #{assignment.id}.", request)
    render json: assignment
  end

  # POST /api/v1/assignments
  def create
    assignment = Assignment.new(assignment_params)
    if assignment.save
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Assignment created: #{assignment.as_json}", request)
      render json: assignment, status: :created
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to create assignment: #{assignment.errors.full_messages.join(', ')}", request)
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/assignments/:id
  def update
    assignment = Assignment.find(params[:id])
    if assignment.update(assignment_params)
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Updated assignment with ID: #{assignment.id}.", request)
      render json: assignment, status: :ok
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to update assignment ID: #{assignment.id}. Errors: #{assignment.errors.full_messages.join(', ')}", request)
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/assignments/:id
  def destroy
    assignment = Assignment.find_by(id: params[:id])
    if assignment
      if assignment.destroy
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Assignment #{assignment.id} was deleted.", request)
        render json: { message: "Assignment deleted successfully!" }, status: :ok
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to delete assignment #{$ERROR_INFO}", request)
        render json: { error: "Failed to delete assignment", details: assignment.errors.full_messages }, status: :unprocessable_entity
      end
    else
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for deletion with ID: #{params[:id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    end
  end
  
  #add participant to assignment
  def add_participant
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for adding participant. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      new_participant = assignment.add_participant(params[:user_id])
      if new_participant.save
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Added participant with User ID: #{params[:user_id]} to assignment ID: #{assignment.id}.", request)
        render json: new_participant, status: :ok
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to add participant to assignment ID: #{assignment.id}. Errors: #{new_participant.errors.full_messages.join(', ')}", request)
        render json: new_participant.errors, status: :unprocessable_entity
      end
    end
  end

  #remove participant from assignment
  def remove_participant
    user = User.find_by(id: params[:user_id])
    assignment = Assignment.find_by(id: params[:assignment_id])
    if user && assignment
      assignment.remove_participant(user.id)
      if assignment.save
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Removed participant with User ID: #{user.id} from assignment ID: #{assignment.id}.", request)
        render json: { message: "Participant removed successfully!" }, status: :ok
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to remove participant from assignment ID: #{assignment.id}. Errors: #{assignment.errors.full_messages.join(', ')}", request)
        render json: assignment.errors, status: :unprocessable_entity
      end
    else
      not_found_message = user ? "Assignment not found" : "User not found"
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "#{not_found_message} while removing participant.", request)
      render json: { error: not_found_message }, status: :not_found
    end
  end


  # make course_id of assignment null
  def remove_assignment_from_course
    assignment = Assignment.find(params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for removing from course. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      assignment = assignment.remove_assignment_from_course
      if assignment.save
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Removed assignment ID: #{assignment.id} from its course.", request)
        render json: assignment , status: :ok
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to remove assignment ID: #{assignment.id} from course. Errors: #{assignment.errors.full_messages.join(', ')}", request)
        render json: assignment.errors, status: :unprocessable_entity
      end
    end
    
  end

  #update course id of an assignment/ assign the assign to some together course
  def assign_course
    assignment = Assignment.find(params[:assignment_id])
    course = Course.find(params[:course_id])
    if assignment && course
      assignment = assignment.assign_course(course.id)
      if assignment.save
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Assigned course ID: #{course.id} to assignment ID: #{assignment.id}.", request)
        render json: assignment, status: :ok
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to assign course to assignment ID: #{assignment.id}. Errors: #{assignment.errors.full_messages.join(', ')}", request)
        render json: assignment.errors, status: :unprocessable_entity
      end
    else
      not_found_message = course ? "Assignment not found" : "Course not found"
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "#{not_found_message} while assigning course.", request)
      render json: { error: not_found_message }, status: :not_found
    end
  end

  #copy existing assignment
  def copy_assignment
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for copying. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      new_assignment = assignment.copy
      if new_assignment.save
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Copied assignment ID: #{assignment.id} to new assignment ID: #{new_assignment.id}.", request)
        render json: new_assignment, status: :ok
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Failed to copy assignment ID: #{assignment.id}. Errors: #{new_assignment.errors.full_messages.join(', ')}", request)
        render json :new_assignment.errors, status: :unprocessable_entity
      end
    end
  end

  # Retrieves assignment details including `has_badge`, `pair_programming_enabled`,
  # `is_calibrated`, and `staggered_and_no_topic`.
  def show_assignment_details
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for showing details. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Fetched details for assignment ID: #{assignment.id}.", request)
      render json: {
        id: assignment.id,
        name: assignment.name,
        has_badge: assignment.has_badge?,
        pair_programming_enabled: assignment.pair_programming_enabled?,
        is_calibrated: assignment.is_calibrated?,
        staggered_and_no_topic: get_staggered_and_no_topic(assignment)
      }, status: :ok
    end
  end

  # check if assignment has topics
  # has_topics is set to true if there is SignUpTopic corresponding to the input assignment id 
  def has_topics
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for checking topics. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      result = assignment.topics?
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Checked topics for assignment ID: #{assignment.id}. Has topics: #{result}", request)
      render json: result, status: :ok
    end
  end

  # check if assignment is a team assignment 
  # true if assignment's max team size is greater than 1
  def team_assignment
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for checking team assignment. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      result = assignment.team_assignment?
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Checked if assignment ID: #{assignment.id} is a team assignment. Result: #{result}", request)
      render json: result, status: :ok
    end
  end

  # check if assignment has valid number of reviews
  # greater than required reviews for a valid review type
  def valid_num_review
    assignment = Assignment.find_by(id: params[:assignment_id])
    review_type = params[:review_type]
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for checking valid number of reviews. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      result = assignment.valid_num_review(review_type)
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Checked valid number of reviews for assignment ID: #{assignment.id}, Review type: #{review_type}. Result: #{result}", request)
      render json: result, status: :ok
    end
  end

  # check if assignment has teams
  # true if there exists a team corresponding to the input assignment id
  def has_teams
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for checking teams. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      result = assignment.teams?
      ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Checked teams for assignment ID: #{assignment.id}. Has teams: #{result}", request)
      render json: result, status: :ok
    end
  end

  # check if assignment has varying rubric across rounds
  # set to true if rubrics vary across rounds in assignment else false
  def varying_rubrics_by_round?
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "Assignment not found for checking varying rubrics. ID: #{params[:assignment_id]}", request)
      render json: { error: "Assignment not found" }, status: :not_found
    else
      if AssignmentQuestionnaire.exists?(assignment_id: assignment.id)
        result = assignment.varying_rubrics_by_round?
        ExpertizaLogger.info LoggerMessage.new(controller_name, session[:user].name, "Checked varying rubrics by round for assignment ID: #{assignment.id}. Result: #{result}", request)
        render json: result, status: :ok
      else
        ExpertizaLogger.error LoggerMessage.new(controller_name, session[:user].name, "No questionnaire exists for assignment ID: #{assignment.id}.", request)
        render json: { error: "No questionnaire/rubric exists for this assignment." }, status: :not_found
      end
    end
  end
  
  private
  # Only allow a list of trusted parameters through.
  def assignment_params
    params.require(:assignment).permit(:title, :description)
  end

  # Helper method to determine staggered_and_no_topic for the assignment
  def get_staggered_and_no_topic(assignment)
    topic_id = SignedUpTeam
               .joins(team: :teams_users)
               .where(teams_users: { user_id: current_user.id, team_id: Team.where(assignment_id: assignment.id).pluck(:id) })
               .pluck(:sign_up_topic_id)
               .first

    assignment.staggered_and_no_topic?(topic_id)
  end
end