class AssignmentsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  # Analogous to CoursesController#action_allowed? — both delegate ownership
  # checks to current_user_can_manage?. The only intentional difference is the
  # collection-action gate: TAs may create and list assignments (for courses
  # they are mapped to), whereas only Instructors and above may create courses.
  def action_allowed?
    return current_user_has_ta_privileges? if action_name.in?(%w[index create])

    assignment = Assignment.find_by(id: params[:id] || params[:assignment_id])
    return true unless assignment  # let the action itself render 404

    current_user_can_manage?(assignment)
  end

  # GET /assignments
  def index
    assignments = if current_user_has_super_admin_privileges?
                    Assignment.all
                  elsif current_user_has_admin_privileges?
                    Assignment.where(instructor_id: current_user.self_and_descendant_ids)
                  elsif current_user_is_a?('Instructor')
                    Assignment.where(instructor_id: current_user.id)
                              .or(Assignment.where(course_id: Course.where(instructor_id: current_user.id).select(:id)))
                  elsif current_user_is_a?('Teaching Assistant')
                    Assignment.where(course_id: current_user_ta_course_ids)
                  else
                    Assignment.none
                  end
    render json: assignments
  end

  # GET /assignments/:id
  def show
    assignment = Assignment.find(params[:id])
    data = assignment.attributes
    data['assignment_questionnaires'] = assignment.assignment_questionnaires
      .includes(:questionnaire)
      .map { |aq| aq.attributes.merge('questionnaire' => aq.questionnaire&.attributes) }
    render body: data.to_json, content_type: 'application/json'
  end

  # POST /assignments
  def create
    assignment = Assignment.new(assignment_params)
    if assignment.save
      render json: assignment, status: :created
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /assignments/:id
  def update
    assignment = Assignment.find(params[:id])
    if assignment.update(assignment_params)
      render body: assignment.attributes.to_json, content_type: 'application/json', status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  def not_found
    render json: { error: "Assignment not found" }, status: :not_found
  end

  # DELETE /assignments/:id
  def destroy
    assignment = Assignment.find_by(id: params[:id])
    if assignment
      if assignment.destroy
        render json: { message: "Assignment deleted successfully!" }, status: :ok
      else
        render json: { error: "Failed to delete assignment", details: assignment.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Assignment not found" }, status: :not_found
    end
  end
  
  # When a user wants to change the min/max score scale for a rubric, the code
  # needs to find how many previously assigned ReviewGrade scores would become
  # invalid (out of bounds) under the new scale, so the UI can warn the
  # instructor before saving the change.
  # GET /assignments/:id/review_grades_out_of_bounds?min=0&max=4
  def review_grades_out_of_bounds
    assignment = Assignment.find_by(id: params[:id])
    return render json: { error: "Assignment not found" }, status: :not_found unless assignment

    new_min = params[:min].presence&.to_f
    new_max = params[:max].presence&.to_f

    participant_ids = AssignmentParticipant.where(parent_id: assignment.id).pluck(:id)
    grades = ReviewGrade.where(participant_id: participant_ids).pluck(:grade_for_reviewer).compact

    conflicts = grades.count do |g|
      (new_min && g < new_min) || (new_max && g > new_max)
    end

    render json: { conflict_count: conflicts }, status: :ok
  end

  #add participant to assignment
  def add_participant
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      new_participant = assignment.add_participant(params[:user_id])
      if new_participant.save
        render json: new_participant, status: :ok
      else
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
        render json: { message: "Participant removed successfully!" }, status: :ok
      else
        render json: assignment.errors, status: :unprocessable_entity
      end
    else
      not_found_message = user ? "Assignment not found" : "User not found"
      render json: { error: not_found_message }, status: :not_found
    end
  end


  # make course_id of assignment null
  def remove_assignment_from_course
    assignment = Assignment.find(params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      assignment = assignment.remove_assignment_from_course
      if assignment.save
        render json: assignment , status: :ok
      else
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
        render json: assignment, status: :ok
      else
        render json: assignment.errors, status: :unprocessable_entity
      end
    else
      not_found_message = course ? "Assignment not found" : "Course not found"
      render json: { error: not_found_message }, status: :not_found
    end
  end

  #copy existing assignment
  def copy_assignment
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      new_assignment = assignment.copy
      if new_assignment.save
        render json: new_assignment, status: :ok
      else
        render json :new_assignment.errors, status: :unprocessable_entity
      end
    end
  end

  # Retrieves assignment details including `has_badge`, `pair_programming_enabled`,
  # `is_calibrated`, and `staggered_and_no_topic`.
  def show_assignment_details
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
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
  # has_topics is set to true if there is ProjectTopic corresponding to the input assignment id 
  def has_topics
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.topics?, status: :ok
    end
  end

  # check if assignment is a team assignment 
  # true if assignment's max team size is greater than 1
  def team_assignment
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.team_assignment?, status: :ok
    end
  end

  # check if assignment has valid number of reviews
  # greater than required reviews for a valid review type
  def valid_num_review
    assignment = Assignment.find_by(id: params[:assignment_id])
    review_type = params[:review_type]
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.valid_num_review(review_type), status: :ok
    end
  end

  # check if assignment has teams
  # true if there exists a team corresponding to the input assignment id
  def has_teams
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      render json: assignment.teams?, status: :ok
    end
  end

  # check if assignment has varying rubric across rounds
  # set to true if rubrics vary across rounds in assignment else false
  def varying_rubrics_by_round?
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
    else
      if AssignmentQuestionnaire.exists?(assignment_id: assignment.id)
        render json: assignment.varying_rubrics_by_round?, status: :ok
      else
        render json: { error: "No questionnaire/rubric exists for this assignment." }, status: :not_found
      end
    end
  end
  
  private
  # Only allow a list of trusted parameters through.
  def assignment_params
    params.require(:assignment).permit(
      # Real DB columns
      :name,
      :directory_path,
      :spec_location,
      :private,
      :course_id,
      :require_quiz,
      :has_teams,
      :max_team_size,
      :has_topics,
      :review_topic_threshold,
      :max_reviews_per_submission,
      :days_between_submissions,
      :late_policy_id,
      :is_penalty_calculated,
      :calculate_penalty,
      :vary_by_round,
      :rounds_of_reviews,
      :instructor_grade_min_score,
      :instructor_grade_max_score,
      # Virtual attr_accessors defined on Assignment
      :title,
      :description,
      # DB boolean columns
      :has_badge,          # legacy column from old Expertiza schema; not actively used but kept to avoid unknown-attribute errors on round-trips
      :enable_pair_programming,
      :is_calibrated,
      :staggered_deadline,
      # Nested assignment_questionnaires
      assignment_questionnaires_attributes: [:id, :questionnaire_id, :used_in_round, :questionnaire_weight, :_destroy]
    )
  end

  # Helper method to determine staggered_and_no_topic for the assignment
  def get_staggered_and_no_topic(assignment)
    topic_id = SignedUpTeam
               .joins(team: :teams_users)
               .where(teams_users: { user_id: current_user.id, team_id: Team.where(parent_id: assignment.id).pluck(:id) })
               .pluck(:project_topic_id)
               .first

    assignment.staggered_and_no_topic?(topic_id)
  end
end