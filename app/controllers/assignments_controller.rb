class AssignmentsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

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

  # GET /assignments/:assignment_id/calibration_data
  # Returns a list of calibration participants (teams) and their submitted content.
  def calibration_submissions
    assignment = Assignment.find_by(id: params[:assignment_id])
    if assignment.nil?
      render json: { error: "Assignment not found" }, status: :not_found
      return
    end

    # Find all ReviewResponseMaps that are flagged for calibration for this assignment.
    calibration_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id, calibration: true)

    calibration_entries = calibration_maps.map do |map|
      team = map.reviewee # The team being reviewed

      # 1. Gather Submitted Content
      hyperlinks = team.submitted_hyperlinks.present? ? JSON.parse(team.submitted_hyperlinks) : []

      # 2. Gather Files
      files = []
      if File.exist?(team.path.to_s)
        Dir.entries(team.path.to_s).each do |entry|
          next if entry == '.' || entry == '..'
          entry_path = File.join(team.path.to_s, entry)
          unless File.directory?(entry_path)
            files << {
              name: entry,
              size: File.size(entry_path),
              modified_at: File.mtime(entry_path)
            }
          end
        end
      end

      # 3. Gather Instructor Review
      instructor_response = map.responses.last
      instructor_review = instructor_response ? {
        response_id: instructor_response.id,
        status: instructor_response.is_submitted ? "Completed" : "In Progress",
        updated_at: instructor_response.updated_at
      } : nil

      # 4. Gather Student Reviews (Other maps for the same team that are NOT for calibration)
      student_maps = ReviewResponseMap.where(reviewee_id: team.id, reviewed_object_id: assignment.id, calibration: false)
      student_reviews = student_maps.map do |sm|
        resp = sm.responses.last
        next unless resp # Skip if no response has been started
        {
          reviewer_name: sm.reviewer.fullname,
          response_id: resp.id,
          is_submitted: resp.is_submitted,
          updated_at: resp.updated_at
        }
      end.compact

      # 4. Gather Student Reviews (Logic is now correct and single-block)
      student_maps = ReviewResponseMap.where(reviewee_id: team.id, reviewed_object_id: assignment.id, calibration: false)
      student_reviews = student_maps.map do |sm|
        resp = sm.responses.last
        next unless resp # Skip if no response has been started
        {
          reviewer_name: sm.reviewer.fullname,
          response_id: resp.id,
          is_submitted: resp.is_submitted,
          updated_at: resp.updated_at
        }
      end.compact

      {
        team_id: team.id,
        team_name: team.name,
        submitted_content: {
          hyperlinks: hyperlinks,
          files: files
        },
        instructor_review: instructor_review,
        student_reviews: student_reviews
      }
    end

    render json: {
      assignment_id: assignment.id,
      calibration_entries: calibration_entries
    }, status: :ok
  end

  # app/controllers/assignments_controller.rb

  # GET /assignments/:assignment_id/calibration_reviews/:team_id
  # Returns instructor response, latest student responses, rubric metadata, and summary distribution.
  def calibration_reviews
    assignment = Assignment.find_by(id: params[:assignment_id])
    team = AssignmentTeam.find_by(id: params[:team_id], parent_id: assignment&.id)

    if assignment.nil? || team.nil?
      render json: { error: "Assignment or Team not found" }, status: :not_found
      return
    end

    # 1. Fetch Rubric Items (Questions)
    # Fetch items from all associated ReviewQuestionnaires for this assignment.
    questionnaires = assignment.assignment_questionnaires.joins(:questionnaire)
                               .where(questionnaires: { questionnaire_type: 'ReviewQuestionnaire' })
                               .map(&:questionnaire)

    rubric_items = questionnaires.flat_map(&:items).sort_by(&:seq)

    # 2. Fetch Instructor's Calibration Response (The "Gold Standard")
    # This is the review for the team where calibration is true.
    instructor_map = ReviewResponseMap.find_by(reviewed_object_id: assignment.id, reviewee_id: team.id, calibration: true)
    instructor_response = instructor_map&.responses&.last
    instructor_data = instructor_response ? {
      response_id: instructor_response.id,
      additional_comment: instructor_response.additional_comment,
      answers: instructor_response.scores.map { |a| { item_id: a.item_id, answer: a.answer, comments: a.comments } }
    } : nil

    # 3. Fetch Student Responses for the same team
    student_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id, reviewee_id: team.id, calibration: false)
    student_responses_data = student_maps.map do |sm|
      resp = sm.responses.last
      next unless resp
      {
        reviewer_name: sm.reviewer.fullname,
        response_id: resp.id,
        additional_comment: resp.additional_comment,
        updated_at: resp.updated_at,
        answers: resp.scores.map { |a| { item_id: a.item_id, answer: a.answer, comments: a.comments } }
      }
    end.compact

    # 4. Calculate Per-Rubric-Item Summary Distribution across all student reviews
    summary = rubric_items.each_with_object({}) do |item, hash|
      next unless item.scored?

      # Collect scores for this specific item from all student reviews
      item_scores = student_responses_data.map do |sr|
        sr[:answers].find { |a| a[:item_id] == item.id }&.[](:answer)
      end.compact

      # Create a distribution map: { score_value => count }
      distribution = item_scores.each_with_object(Hash.new(0)) { |score, counts| counts[score] += 1 }

      hash[item.id] = {
        average: item_scores.empty? ? 0 : (item_scores.sum.to_f / item_scores.size).round(2),
        distribution: distribution
      }
    end

    render json: {
      assignment_id: assignment.id,
      team_id: team.id,
      team_name: team.name,
      rubric: rubric_items.as_json,
      instructor_response: instructor_data,
      student_responses: student_responses_data,
      summary: summary
    }, status: :ok
  end

    private
  # Only allow a list of trusted parameters through.
  def assignment_params
    params.require(:assignment).permit(
      :name,
      :title,
      :description,
      :directory_path,
      :spec_location,
      :private,
      :show_template_review,
      :require_quiz,
      :has_badge,
      :staggered_deadline,
      :is_calibrated,
      :has_teams,
      :max_team_size,
      :show_teammate_review,
      :is_pair_programming,
      :has_mentors,
      :has_topics,
      :review_topic_threshold,
      :maximum_number_of_reviews_per_submission,
      :review_strategy,
      :review_rubric_varies_by_round,
      :review_rubric_varies_by_topic,
      :review_rubric_varies_by_role,
      :has_max_review_limit,
      :set_allowed_number_of_reviews_per_reviewer,
      :set_required_number_of_reviews_per_reviewer,
      :is_review_anonymous,
      :is_review_done_by_teams,
      :allow_self_reviews,
      :reviews_visible_to_other_reviewers,
      :number_of_review_rounds,
      :days_between_submissions,
      :late_policy_id,
      :is_penalty_calculated,
      :calculate_penalty,
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