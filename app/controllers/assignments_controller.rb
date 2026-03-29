class AssignmentsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  # Review rubrics from the SPA use questionnaire_type "Review rubric"; legacy data may use "ReviewQuestionnaire".
  # calibration_reviews must match both or the rubric array is always empty.
  REVIEW_RUBRIC_QUESTIONNAIRE_TYPES = %w[Review rubric ReviewQuestionnaire].freeze

  # GET /assignments
  def index
    assignments = Assignment.all
    render json: assignments
  end

  # GET /assignments/:id
  def show
    assignment = Assignment.find(params[:id])
    render json: assignment_json(assignment)
  end

  # POST /assignments
  def create
    assignment = Assignment.new(assignment_params)
    if assignment.save
      render json: assignment_json(assignment), status: :created
    else
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /assignments/:id
  def update
    assignment = Assignment.find(params[:id])
    Rails.logger.info "ASSIGNMENT UPDATE PARAMS: #{assignment_params.to_h.inspect}"
    if assignment.update(assignment_params)
      Rails.logger.info "ASSIGNMENT UPDATE SUCCESS: #{assignment.assignment_questionnaires.reload.inspect}"
      render json: assignment_json(assignment), status: :ok
    else
      Rails.logger.error "ASSIGNMENT UPDATE FAIL: #{assignment.errors.full_messages}"
      render json: assignment.errors, status: :unprocessable_entity
    end
  end

  def assignment_json(assignment)
    assignment.as_json(
      include: {
        assignment_questionnaires: {
          include: { questionnaire: { only: %i[id name] } }
        },
        due_dates: {}
      }
    ).merge(
      'num_review_rounds' => assignment.num_review_rounds,
      'varying_rubrics_by_round' => assignment.varying_rubrics_by_round?,
      'has_teams' => assignment.teams?,
      'has_topics' => assignment.topics?,
      'show_teammate_review' => (assignment.show_teammate_review == 'true' || assignment.show_teammate_review == true || assignment.show_teammate_reviews),
      'is_pair_programming' => (assignment.is_pair_programming == 'true' || assignment.is_pair_programming == true || assignment.enable_pair_programming),
      'show_template_review' => (assignment.show_template_review == 'true' || assignment.show_template_review == true),
      'has_mentors' => (assignment.has_mentors == 'true' || assignment.has_mentors == true),
      'has_quizzes' => (assignment.has_quizzes == 'true' || assignment.has_quizzes == true),
      'calibration_for_training' => (assignment.calibration_for_training == 'true' || assignment.calibration_for_training == true),
      'available_to_students' => (assignment.available_to_students == 'true' || assignment.available_to_students == true),
      'allow_topic_suggestion_from_students' => (assignment.allow_topic_suggestion_from_students == 'true' || assignment.allow_topic_suggestion_from_students == true),
      'enable_bidding_for_topics' => (assignment.enable_bidding_for_topics == 'true' || assignment.enable_bidding_for_topics == true),
      'enable_bidding_for_reviews' => (assignment.enable_bidding_for_reviews == 'true' || assignment.enable_bidding_for_reviews == true),
      'enable_authors_to_review_other_topics' => (assignment.enable_authors_to_review_other_topics == 'true' || assignment.enable_authors_to_review_other_topics == true),
      'allow_reviewer_to_choose_topic_to_review' => (assignment.allow_reviewer_to_choose_topic_to_review == 'true' || assignment.allow_reviewer_to_choose_topic_to_review == true),
      'allow_participants_to_create_bookmarks' => (assignment.allow_participants_to_create_bookmarks == 'true' || assignment.allow_participants_to_create_bookmarks == true),
      'auto_assign_mentors' => (assignment.auto_assign_mentors == 'true' || assignment.auto_assign_mentors == true),
      'staggered_deadline_assignment' => (assignment.staggered_deadline_assignment == 'true' || assignment.staggered_deadline_assignment == true),
      'maximum_number_of_reviews_per_submission' => assignment.maximum_number_of_reviews_per_submission.to_i,
      'review_strategy' => assignment.review_strategy,
      'review_rubric_varies_by_round' => (assignment.review_rubric_varies_by_round == 'true' || assignment.review_rubric_varies_by_round == true),
      'review_rubric_varies_by_topic' => (assignment.review_rubric_varies_by_topic == 'true' || assignment.review_rubric_varies_by_topic == true),
      'review_rubric_varies_by_role' => (assignment.review_rubric_varies_by_role == 'true' || assignment.review_rubric_varies_by_role == true),
      'has_max_review_limit' => (assignment.has_max_review_limit == 'true' || assignment.has_max_review_limit == true),
      'set_allowed_number_of_reviews_per_reviewer' => assignment.set_allowed_number_of_reviews_per_reviewer.to_i,
      'set_required_number_of_reviews_per_reviewer' => assignment.set_required_number_of_reviews_per_reviewer.to_i,
      'is_review_anonymous' => (assignment.is_review_anonymous == 'true' || assignment.is_review_anonymous == true),
      'is_review_done_by_teams' => (assignment.is_review_done_by_teams == 'true' || assignment.is_review_done_by_teams == true),
      'allow_self_reviews' => (assignment.allow_self_reviews == 'true' || assignment.allow_self_reviews == true),
      'reviews_visible_to_other_reviewers' => (assignment.reviews_visible_to_other_reviewers == 'true' || assignment.reviews_visible_to_other_reviewers == true),
      'number_of_review_rounds' => assignment.number_of_review_rounds.to_i,
      'allow_tag_prompts' => (assignment.allow_tag_prompts == 'true' || assignment.allow_tag_prompts == true),
      'use_signup_deadline' => (assignment.use_signup_deadline == 'true' || assignment.use_signup_deadline == true),
      'use_drop_topic_deadline' => (assignment.use_drop_topic_deadline == 'true' || assignment.use_drop_topic_deadline == true),
      'use_team_formation_deadline' => (assignment.use_team_formation_deadline == 'true' || assignment.use_team_formation_deadline == true),
      'weights' => (assignment.weights || []).map(&:to_i),
      'notification_limits' => (assignment.notification_limits || []).map(&:to_i),
      'use_date_updater' => (assignment.use_date_updater || []).map { |v| v == 'true' || v == true },
      'submission_allowed' => (assignment.submission_allowed || []).map { |v| v == 'true' || v == true },
      'review_allowed' => (assignment.review_allowed || []).map { |v| v == 'true' || v == true },
      'teammate_allowed' => (assignment.teammate_allowed || []).map { |v| v == 'true' || v == true },
      'metareview_allowed' => (assignment.metareview_allowed || []).map { |v| v == 'true' || v == true },
      'reminder' => (assignment.reminder || []).map(&:to_i),
      'review_topic_threshold' => assignment.review_topic_threshold.to_i,
      'days_between_submissions' => assignment.days_between_submissions.to_i,
      'late_policy_id' => assignment.late_policy_id.to_i,
      'is_penalty_calculated' => (assignment.is_penalty_calculated == 'true' || assignment.is_penalty_calculated == true),
      'calculate_penalty' => (assignment.calculate_penalty == 'true' || assignment.calculate_penalty == true),
      'apply_late_policy' => (assignment.apply_late_policy == 'true' || assignment.apply_late_policy == true)
    )
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
    begin
      assignment = Assignment.find_by(id: params[:assignment_id])
      if assignment.nil?
        render json: { error: "Assignment not found" }, status: :not_found
        return
      end

      # Find all ReviewResponseMaps that are flagged for calibration for this assignment.
      calibration_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true)

      calibration_entries = calibration_maps.map do |map|
        team = map.reviewee # The team being reviewed
        next unless team # Ensure team exists

        # 1. Gather Submitted Content
        hyperlinks = []
        begin
          hyperlinks = team.submitted_hyperlinks.present? ? JSON.parse(team.submitted_hyperlinks) : []
        rescue JSON::ParserError
          hyperlinks = []
        rescue StandardError
          hyperlinks = []
        end

        # 2. Gather Files
        files = []
        if team.respond_to?(:path) && File.exist?(team.path.to_s)
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
        student_maps = ReviewResponseMap.where(reviewee_id: team.id, reviewed_object_id: assignment.id, for_calibration: false)
        student_reviews = student_maps.map do |sm|
          resp = sm.responses.last
          next unless resp # Skip if no response has been started
          reviewer = sm.reviewer
          reviewer_name = reviewer ? (reviewer.fullname rescue 'Unknown reviewer') : 'Unknown reviewer'
          {
            reviewer_name: reviewer_name,
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
      end.compact

      render json: {
        assignment_id: assignment.id,
        calibration_entries: calibration_entries
      }, status: :ok
    end
  end

  # app/controllers/assignments_controller.rb

  # GET /assignments/:assignment_id/calibration_reviews/:team_id
  # OR /assignments/:assignment_id/calibration_reports/:id
  # Returns instructor response, latest student responses, rubric metadata, and summary distribution.
  def calibration_reviews
    begin
      assignment = Assignment.find_by(id: params[:assignment_id])
      # Handle both :team_id (old/direct) and :id (from response_map_id)
      if params[:team_id].present?
        team = AssignmentTeam.find_by(id: params[:team_id], parent_id: assignment&.id)
        Rails.logger.info "CALIBRATION REVIEWS: Searching by team_id=#{params[:team_id]}, found team: #{team&.id}"
      elsif params[:id].present?
        # In CalibrationReview.tsx, :id is response_map_id
        map = ReviewResponseMap.find_by(id: params[:id], reviewed_object_id: assignment&.id, for_calibration: true)
        team = map&.reviewee
        Rails.logger.info "CALIBRATION REVIEWS: Searching by map_id=#{params[:id]}, found map: #{map&.id}, found team: #{team&.id}"
      end

      if assignment.nil? || team.nil?
        Rails.logger.warn "CALIBRATION REVIEWS: Assignment or Team not found. Assignment: #{assignment&.id}, Team: #{team&.id}"
        render json: { error: 'Assignment or Team not found' }, status: :not_found
        return
      end

      # 1. Fetch Rubric Items (Questions)
      # Match both SPA ("Review rubric") and legacy ("ReviewQuestionnaire") questionnaire_type values.
      questionnaires = assignment.assignment_questionnaires
                                    .joins(:questionnaire)
                                    .where(questionnaires: { questionnaire_type: REVIEW_RUBRIC_QUESTIONNAIRE_TYPES })
                                    .includes(questionnaire: :items)
                                    .map(&:questionnaire)
                                    .uniq

      rubric_items = questionnaires.flat_map(&:items).index_by(&:id).values.sort_by(&:seq)

      # If nothing matched (e.g. uncommon type string), fall back to any questionnaire linked to the assignment.
      if rubric_items.empty?
        questionnaires = assignment.questionnaires.includes(:items).distinct.to_a
        rubric_items = questionnaires.flat_map(&:items).index_by(&:id).values.sort_by(&:seq)
        Rails.logger.info "CALIBRATION REVIEWS: Fallback — using all linked questionnaires; #{rubric_items.size} items"
      end

      Rails.logger.info "CALIBRATION REVIEWS: Found #{rubric_items.size} rubric items from #{questionnaires.size} questionnaires"

      # 2. Fetch Instructor's Calibration Response (The "Gold Standard")
      # This is the review for the team where calibration is true.
      instructor_map = ReviewResponseMap.find_by(reviewed_object_id: assignment.id, reviewee_id: team.id, for_calibration: true)
      
      # If the map wasn't found by team_id (reviewee_id), try finding it by map_id if passed
      if instructor_map.nil? && params[:id].present?
        instructor_map = ReviewResponseMap.find_by(id: params[:id], reviewed_object_id: assignment.id, for_calibration: true)
      end

      instructor_response = instructor_map&.responses&.last
      Rails.logger.info "CALIBRATION REVIEWS: Instructor map: #{instructor_map&.id}, response: #{instructor_response&.id}"
      
      # START: TEMPORARY MOCK GOLD STANDARD (Duplicate from CalibrationResponseMapsController for safety)
      unless instructor_response || instructor_map.nil?
        begin
          Rails.logger.info "MOCK CALIBRATION REPORT: Creating response for map #{instructor_map.id}"
          instructor_response = Response.create!(map_id: instructor_map.id, is_submitted: true, additional_comment: 'MOCK GOLD STANDARD: Automatically generated for report view.')
          
          # Force reload of assignment_questionnaires to be sure
          assignment.assignment_questionnaires.reload
          q_ids = assignment.assignment_questionnaires.pluck(:questionnaire_id)
          questionnaires = Questionnaire.where(id: q_ids)
          target_questionnaire = questionnaires.find_by(questionnaire_type: 'Review rubric') || 
                                 questionnaires.find_by(questionnaire_type: 'ReviewQuestionnaire') || 
                                 questionnaires.first

          if target_questionnaire
            Rails.logger.info "MOCK CALIBRATION REPORT: Using questionnaire #{target_questionnaire.id} for answers"
            target_questionnaire.items.each do |item|
              next unless item.scored?
              Answer.create!(response_id: instructor_response.id, item_id: item.id, answer: target_questionnaire.max_question_score, comments: "Predefined score for #{item.txt}")
            end
          else
            Rails.logger.warn "MOCK CALIBRATION REPORT: No questionnaire found for assignment #{assignment.id}. Q IDs checked: #{q_ids}"
          end
        rescue StandardError => e
          Rails.logger.error "MOCK CALIBRATION REPORT ERROR: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
      # END: TEMPORARY MOCK GOLD STANDARD
      
      instructor_data = instructor_response ? {
        response_id: instructor_response.id,
        additional_comment: instructor_response.additional_comment,
        answers: (instructor_response.scores || []).map { |a| { item_id: a.item_id, answer: a.answer, comments: a.comments } }
      } : nil

      # 3. Fetch Student Responses for the same team
      student_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id, reviewee_id: team.id, for_calibration: false)
      student_responses_data = student_maps.map do |sm|
        resp = sm.responses.last
        next unless resp
        reviewer = sm.reviewer
        reviewer_name = reviewer ? (reviewer.fullname rescue 'Unknown reviewer') : 'Unknown reviewer'
        {
          reviewer_name: reviewer_name,
          response_id: resp.id,
          additional_comment: resp.additional_comment,
          updated_at: resp.updated_at,
          answers: (resp.scores || []).map { |a| { item_id: a.item_id, answer: a.answer, comments: a.comments } }
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

      # 5. Gather Submitted Content
      hyperlinks = []
      begin
        hyperlinks = team.submitted_hyperlinks.present? ? JSON.parse(team.submitted_hyperlinks) : []
      rescue JSON::ParserError
        hyperlinks = []
      rescue StandardError
        hyperlinks = []
      end

      files = []
      if team.respond_to?(:path) && File.exist?(team.path.to_s)
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

      # 6. Build per_item_summary for frontend
      per_item_summary = rubric_items.map do |item|
        item_summary = summary[item.id] || { average: 0, distribution: {} }
        instructor_score = instructor_data&.[](:answers)&.find { |a| a[:item_id] == item.id }&.[](:answer)
        
        # Calculate agree/near/disagree if instructor score is present
        agree = 0
        near = 0
        disagree = 0
        
        if instructor_score
          item_summary[:distribution].each do |score, count|
            diff = (score.to_i - instructor_score.to_i).abs
            if diff == 0
              agree += count
            elsif diff == 1
              near += count
            else
              disagree += count
            end
          end
        end

        {
          item_id: item.id,
          seq: item.seq,
          txt: item.txt,
          question_type: item.question_type.presence || item.type.to_s,
          agree: agree,
          near: near,
          disagree: disagree,
          distribution: item_summary[:distribution],
          instructor_score: instructor_score
        }
      end

      render json: {
        assignment_id: assignment.id,
        response_map_id: params[:id], # Include if called via calibration_reports
        team_id: team.id,
        team_name: team.name,
        rubric: rubric_items.as_json,
        instructor_response: instructor_data,
        student_responses: student_responses_data,
        summary: summary, # Keep for compatibility
        per_item_summary: per_item_summary, # For CalibrationReview.tsx
        submitted_content: {
          hyperlinks: hyperlinks,
          files: files.map { |f| f[:name] } # Frontend expects string[] for files
        }
      }, status: :ok
    end
  end

    private
  # Only allow a list of trusted parameters through.
  def assignment_params
    params.require(:assignment).permit(
      :name,
      :instructor_id,
      :course_id,
      :title,
      :description,
      :directory_path,
      :spec_location,
      :private,
      :require_quiz,
      :has_badge,
      :staggered_deadline,
      :is_calibrated,
      :has_teams,
      :max_team_size,
      :show_teammate_reviews,
      :enable_pair_programming,
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
      :allow_tag_prompts,
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
      :show_template_review,
      :show_teammate_review,
      :is_pair_programming,
      :has_mentors,
      :has_quizzes,
      :calibration_for_training,
      :available_to_students,
      :allow_topic_suggestion_from_students,
      :enable_bidding_for_topics,
      :enable_bidding_for_reviews,
      :enable_authors_to_review_other_topics,
      :allow_reviewer_to_choose_topic_to_review,
      :allow_participants_to_create_bookmarks,
      :auto_assign_mentors,
      :staggered_deadline_assignment,
      :maximum_number_of_reviews_per_submission,
      :review_topic_threshold,
      :days_between_submissions,
      :late_policy_id,
      :is_penalty_calculated,
      :calculate_penalty,
      :apply_late_policy,
      :allow_tag_prompts,
      assignment_questionnaires_attributes: [:id, :questionnaire_id, :used_in_round, :_destroy],
      weights: [],
      notification_limits: [],
      reminder: [],
      use_date_updater: [],
      submission_allowed: [],
      review_allowed: [],
      teammate_allowed: [],
      metareview_allowed: []
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