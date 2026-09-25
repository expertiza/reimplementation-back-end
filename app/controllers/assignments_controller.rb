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
    data['due_dates'] = assignment.due_dates.map(&:attributes)
    render body: data.to_json, content_type: 'application/json'
  end

  # POST /assignments
  def create
    assignment = Assignment.new(assignment_params)
    # Mirror old Expertiza behavior: instructor comes from the course when one is
    # selected (so an admin creating an assignment in another instructor's course
    # doesn't accidentally take ownership). Fall back to current_user only when no
    # course is attached (standalone assignment).
    if assignment.course_id.present?
      assignment.instructor_id = Course.find_by(id: assignment.course_id)&.instructor_id || current_user.id
    else
      assignment.instructor_id = current_user.id
    end
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
      data = assignment.attributes
      data['due_dates'] = assignment.due_dates.map(&:attributes)
      render body: data.to_json, content_type: 'application/json', status: :ok
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # GET /assignments/:id/calibration_submissions
  # Returns all teams for the assignment with their submitted content and the
  # instructor's calibration review status — mirroring old Expertiza's _calibration.html.erb.
  def calibration_submissions
    assignment = Assignment.find(params[:id])

    instructor_participant = AssignmentParticipant.find_by(
      parent_id: assignment.id,
      user_id:   assignment.instructor_id
    )

    teams = AssignmentTeam.where(parent_id: assignment.id)

    payload = teams.map do |team|
      member_names = TeamsUser.where(team_id: team.id).filter_map do |tu|
        user = User.find_by(id: tu.user_id)
        next unless user
        "#{user.name} (#{user.full_name})"
      end.join(', ')

      # Resolve calibration review map and its status
      calibration_map = instructor_participant && ReviewResponseMap.find_by(
        reviewed_object_id: assignment.id,
        reviewer_id:        instructor_participant.id,
        reviewee_id:        team.id,
        calibrate_to:       true
      )

      review_status = if calibration_map.nil?
                        'not_started'
                      elsif calibration_map.responses.exists?(is_submitted: true)
                        'completed'
                      elsif calibration_map.responses.exists?
                        'in_progress'
                      else
                        'not_started'
                      end

      hyperlinks = team.hyperlinks rescue []
      files      = SubmissionRecord.where(assignment_id: assignment.id, team_id: team.id, record_type: 'file')
                                   .pluck(:content)

      {
        id:                team.id,
        participant_name:  member_names,
        review_status:     review_status,
        submitted_content: { hyperlinks: hyperlinks, files: files }
      }
    end

    render json: payload, status: :ok
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
      # Identity
      :name, :title, :description, :directory_path, :spec_location, :course_id,
      # Visibility
      :private,
      # Feature flags (DB columns or aliases defined in Assignment model)
      :require_quiz, :has_badge, :staggered_deadline, :is_calibrated,
      :has_teams, :max_team_size,
      :show_teammate_review,        # alias → show_teammate_reviews
      :is_pair_programming,         # alias → enable_pair_programming
      :has_topics,
      :available_to_students,              # alias → availability_flag
      :allow_tag_prompts,                  # alias → is_answer_tagging_allowed
      :allow_participants_to_create_bookmarks, # alias → use_bookmark
      # Review configuration
      :review_topic_threshold,
      :maximum_number_of_reviews_per_submission, # alias → max_reviews_per_submission
      :review_strategy,                          # alias → review_assignment_strategy
      :review_rubric_varies_by_round,            # alias → vary_by_round
      :review_rubric_varies_by_topic,            # alias → vary_by_topic
      :review_rubric_varies_by_role,             # alias → vary_by_role
      :is_review_anonymous,                      # alias → is_anonymous
      :is_review_done_by_teams,                  # alias → team_reviewing_enabled
      :allow_self_reviews,                       # alias → is_selfreview_enabled
      :reviews_visible_to_other_reviewers,       # alias → reviews_visible_to_all
      :has_max_review_limit,                     # virtual (no DB column, UI toggle only)
      :set_allowed_number_of_reviews_per_reviewer, # alias → num_reviews_allowed
      :set_required_number_of_reviews_per_reviewer, # alias → num_reviews_required
      :number_of_review_rounds,                  # alias → rounds_of_reviews
      :is_role_based,                            # alias → duty_based_assignment
      # Topics / bidding
      :allow_topic_suggestion_from_students,     # alias → allow_suggestions
      :enable_bidding_for_topics,
      :enable_bidding_for_reviews,               # alias → bidding_for_reviews_enabled
      :enable_authors_to_review_other_topics,
      :allow_reviewer_to_choose_topic_to_review, # alias → can_choose_topic_to_review
      :staggered_deadline_assignment,            # alias → staggered_deadline
      # Penalties / late policy
      :days_between_submissions, :late_policy_id, :is_penalty_calculated,
      :calculate_penalty, :apply_late_policy,    # apply_late_policy is virtual
      # Mentors
      :has_mentors, :auto_assign_mentors,        # auto_assign_mentors → auto_assign_mentor
      # UI-only virtual flag
      :show_template_review,
      # Grade scale
      :instructor_grade_min_score, :instructor_grade_max_score,
      # Rubric rows saved via nested attributes
      assignment_questionnaires_attributes: [
        :id, :questionnaire_id, :used_in_round, :questionnaire_weight, :notification_limit, :dropdown, :_destroy
      ],
      due_dates_attributes: [
        :id, :deadline_type_id, :due_at, :round,
        :submission_allowed_id, :review_allowed_id, :teammate_review_allowed_id,
        :flag, :threshold, :_destroy
      ]
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