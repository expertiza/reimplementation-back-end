class AssignmentsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  LEGACY_ASSIGNMENT_PARAM_MAP = {
    show_teammate_review: :show_teammate_reviews,
    is_pair_programming: :enable_pair_programming,
    maximum_number_of_reviews_per_submission: :max_reviews_per_submission,
    review_strategy: :review_assignment_strategy,
    set_allowed_number_of_reviews_per_reviewer: :num_reviews_allowed,
    set_required_number_of_reviews_per_reviewer: :num_reviews_required,
    is_review_anonymous: :is_anonymous,
    allow_self_reviews: :is_selfreview_enabled,
    reviews_visible_to_other_reviewers: :reviews_visible_to_all,
    number_of_review_rounds: :rounds_of_reviews,
    allow_tag_prompts: :is_answer_tagging_allowed,
    available_to_students: :availability_flag,
    allow_topic_suggestion_from_students: :allow_suggestions,
    allow_participants_to_create_bookmarks: :use_bookmark,
    enable_authors_to_review_other_topics: :can_review_same_topic,
    allow_reviewer_to_choose_topic_to_review: :can_choose_topic_to_review,
    staggered_deadline_assignment: :staggered_deadline
  }.freeze

  # GET /assignments
  def index
    assignments = Assignment.all
    render json: assignments
  end

  # GET /assignments/:id
  def show
    assignment = Assignment.find(params[:id])
    render json: assignment
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
      render json: assignment, status: :ok
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
    permitted = params.require(:assignment).permit(
      :name,
      :title,
      :description,
      :directory_path,
      :spec_location,
      :course_id,
      :private,
      :require_quiz,
      :has_badge,
      :staggered_deadline,
      :is_calibrated,
      :has_teams,
      :max_team_size,
      :show_teammate_review,
      :show_teammate_reviews,
      :is_pair_programming,
      :enable_pair_programming,
      :has_mentors,
      :has_topics,
      :vary_by_topic,
      :vary_by_round,
      :review_topic_threshold,
      :maximum_number_of_reviews_per_submission,
      :max_reviews_per_submission,
      :review_strategy,
      :review_assignment_strategy,
      :review_rubric_varies_by_round,
      :review_rubric_varies_by_topic,
      :review_rubric_varies_by_role,
      :has_max_review_limit,
      :set_allowed_number_of_reviews_per_reviewer,
      :num_reviews_allowed,
      :set_required_number_of_reviews_per_reviewer,
      :num_reviews_required,
      :is_review_anonymous,
      :is_anonymous,
      :is_review_done_by_teams,
      :allow_self_reviews,
      :is_selfreview_enabled,
      :reviews_visible_to_other_reviewers,
      :reviews_visible_to_all,
      :number_of_review_rounds,
      :rounds_of_reviews,
      :days_between_submissions,
      :late_policy_id,
      :is_penalty_calculated,
      :calculate_penalty,
      :allow_suggestions,
      :availability_flag,
      :use_bookmark,
      :can_review_same_topic,
      :can_choose_topic_to_review,
      :is_answer_tagging_allowed,
      :staggered_deadline_assignment,
      :allow_tag_prompts,
      :available_to_students,
      :allow_topic_suggestion_from_students,
      :allow_participants_to_create_bookmarks,
      :enable_authors_to_review_other_topics,
      :allow_reviewer_to_choose_topic_to_review,
      :use_signup_deadline,
      :use_drop_topic_deadline,
      :use_team_formation_deadline,
      :use_date_updater,
      :submission_allowed,
      :review_allowed,
      :teammate_allowed,
      :metareview_allowed,
      weights: [],
      notification_limits: [],
      reminder: []
    )

    normalized = permitted.to_h.deep_symbolize_keys

    LEGACY_ASSIGNMENT_PARAM_MAP.each do |legacy_key, current_key|
      next unless normalized.key?(legacy_key)

      normalized[current_key] = normalized.delete(legacy_key)
    end

    allowed_keys = Assignment.attribute_names.map(&:to_sym) + %i[title description]
    ActionController::Parameters.new(normalized.slice(*allowed_keys)).permit!
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
