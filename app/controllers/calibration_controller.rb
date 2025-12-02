# app/controllers/calibration_controller.rb

class CalibrationController < ApplicationController
  # This function retrives all submissions that an intsructor has to review for calibration
  # GET /calibration/assignments/{assignment_id}/submissions
  def get_instructor_calibration_submissions
    assignment_id = params[:assignment_id]

    # Get the instructor's participant ID for this assignment
    instructor_participant_id = get_instructor_participant_id(assignment_id)
    return render json: { error: 'Instructor not found' }, status: :not_found if instructor_participant_id.nil?

    # Find calibration submissions where the INSTRUCTOR is the REVIEWER
    # ReviewResponseMap has reviewee_id as a Team ID
    calibration_submissions = ResponseMap.where(
      reviewed_object_id: assignment_id,
      reviewer_id: instructor_participant_id,
      for_calibration: true
    )

    # Get the details for each calibration submission
    submissions = calibration_submissions.map do |response_map|
      # For ReviewResponseMap, reviewee_id is a Team ID
      reviewee_team = Team.find_by(id: response_map.reviewee_id)
      next unless reviewee_team

      # Get team display name (team name or first member's name)
      team_name = reviewee_team.name.present? ? reviewee_team.name : reviewee_team.participants.first&.user&.full_name || 'Unknown Team'

      # Get the submission content for that team
      submitted_content = get_submitted_content(reviewee_team.id)

      # Check if the review has been started
      review_status = get_review_status(response_map.id)

      {
        team_name: team_name,
        reviewee_id: response_map.reviewee_id,
        response_map_id: response_map.id,
        submitted_content: submitted_content,
        review_status: review_status
      }
    end.compact

    render json: { calibration_submissions: submissions }, status: :ok
  end

  # GET /calibration/calibration_student_report
  # Compares the logged-in student's calibration reviews against the instructor's reviews.
  # Returns detailed breakdown per question including scores, comments, and match statistics.
  def calibration_student_report
    student_participant_id = params[:student_participant_id]
    assignment_id = params[:assignment_id]

    # Validate required parameters
    if student_participant_id.blank? || assignment_id.blank?
      render json: { error: 'Missing required parameters' }, status: :bad_request and return
    end

    # Find all calibration reviews this student completed for this assignment
    student_calibration_maps = ResponseMap.where(
      reviewer_id: student_participant_id,
      reviewed_object_id: assignment_id,
      for_calibration: true
    )

    # Build comparison report for each calibration review
    calibration_reviews = student_calibration_maps.map do |student_response_map|
      # Get reviewee team information
      reviewee_team = Team.find_by(id: student_response_map.reviewee_id)
      next unless reviewee_team

      # Get team display name (consistent with other methods)
      team_name = reviewee_team.name.present? ? reviewee_team.name : reviewee_team.participants.first&.user&.full_name || 'Unknown Team'

      # Get the student's most recent review for this calibration
      student_review = Response.where(map_id: student_response_map.id)
                               .order(updated_at: :desc)
                               .first

      # Get the instructor's review of the same submission
      instructor_review = get_instructor_review_for_reviewee(
        assignment_id,
        student_response_map.reviewee_id
      )

      # Compare the two reviews (includes scores, comments, match rate, etc.)
      comparison_data = if instructor_review && student_review
                          instructor_review_better?(instructor_review, student_review)
                        else
                          { error: 'Missing review data' }
                        end

      {
        reviewee_name: team_name,
        reviewee_id: student_response_map.reviewee_id,
        comparison: comparison_data
      }
    end.compact

    render json: {
      student_participant_id: student_participant_id,
      assignment_id: assignment_id,
      calibration_reviews: calibration_reviews
    }, status: :ok
  end

  # GET /calibration/assignments/:assignment_id/students/:student_participant_id/summary
  # For a given student + assignment, returns info about each submission
  # they calibrated:
  #  - all reviewers (team members who submitted the work)
  #  - all hyperlinks submitted by that user/team
  #  - the for_calibration flag for that calibration review
  def summary
    student_participant_id = params[:student_participant_id].presence
    assignment_id          = params[:assignment_id].presence

    # 1) Hard-missing or empty params → 400
    if student_participant_id.nil? || assignment_id.nil?
      render json: { error: 'Missing required parameters' }, status: :bad_request and return
    end

    # 2) Resolve actual records
    assignment = Assignment.find_by(id: assignment_id)
    student    = Participant.find_by(id: student_participant_id)

    # assignment or participant doesn't exist at all → 404
    unless assignment && student
      render json: { error: 'Assignment or student not found' }, status: :not_found and return
    end

    # 3) Ensure the participant belongs to that assignment
    if student.parent_id != assignment.id
      render json: { error: 'Student is not a participant in this assignment' }, status: :unprocessable_entity and return
    end

    # 4) All calibration maps for this student on this assignment
    # Use ReviewResponseMap – reviewee_id is a Team ID
    student_calibration_maps = ReviewResponseMap.where(
      reviewer_id:        student.id,
      reviewed_object_id: assignment.id,
      for_calibration:    true
    )

    submissions = student_calibration_maps.map do |student_response_map|
      # For ReviewResponseMap, reviewee is a Team
      reviewee_team = student_response_map.reviewee
      next unless reviewee_team

      # IMPORTANT: match the spec's notion of team membership:
      # participants whose parent_id == reviewee_team.id
      team_members = Participant
        .where(parent_id: reviewee_team.id, type: 'AssignmentParticipant')
        .includes(:user)

      reviewers = team_members.map do |member|
        {
          participant_id: member.id,
          full_name:      member.user.full_name
        }
      end

      # Submitted content for this team (hyperlinks + files)
      submitted_content = get_submitted_content(reviewee_team.id) || {}
      hyperlinks = submitted_content[:hyperlinks] ||
                  submitted_content['hyperlinks'] ||
                  []

      {
        reviewee_team_id: reviewee_team.id,
        reviewers:        reviewers,
        hyperlinks:       hyperlinks,
        for_calibration:  student_response_map.for_calibration
      }
    end.compact

    render json: {
      student_participant_id: student.id,
      assignment_id:          assignment.id,
      submissions:            submissions
    }, status: :ok
  end


  # GET /calibration/assignments/:assignment_id/report/:reviewee_id
  # Calculates aggregate statistics for the class on a specific calibration assignment
  # Includes distribution of scores (exact, off by 1, off by 2, etc.)
  def calibration_aggregate_report
    assignment_id = params[:assignment_id]
    reviewee_id   = params[:reviewee_id]

    if assignment_id.blank? || reviewee_id.blank?
      render json: { error: 'Missing required parameters' }, status: :bad_request and return
    end

    # 1. Get the Instructor's Review (Answer Key)
    instructor_review = get_instructor_review_for_reviewee(assignment_id, reviewee_id)
    if instructor_review.nil?
      render json: { error: 'Instructor review not found. Cannot generate report.' }, status: :not_found
      return
    end

    # 2. Find ALL student calibration reviews (excluding the instructor's own self-review)
    instructor_participant_id = get_instructor_participant_id(assignment_id)
    student_calibration_maps = ResponseMap.where(
      reviewed_object_id: assignment_id,
      reviewee_id: reviewee_id,
      for_calibration: true
    ).where.not(reviewer_id: instructor_participant_id)

    # 3. Collect the latest submitted Response for each student
    # (Optimized to load map_id and id to avoid N+1 issues later if expanded)
    student_responses = student_calibration_maps.map do |map|
      Response.where(map_id: map.id).order(updated_at: :desc).first
    end.compact

    # 4. Prepare Answer Data for Processing
    # Optimization: Fetch all student answers in one query and group by Item ID
    # This prevents running a DB query for every single question inside the loop
    instructor_answers = Answer.where(response_id: instructor_review.id)
    student_answers_flat = Answer.where(response_id: student_responses.map(&:id))
    student_answers_by_item = student_answers_flat.group_by(&:item_id)

    # 5. Process Question Breakdown
    total_match_rate_sum = 0

    question_breakdown = instructor_answers.map do |inst_answer|
      stud_answers_for_q = student_answers_by_item[inst_answer.item_id] || []

      # Use helper to calculate all stats (Match rate, off-by-1, etc.)
      stats = calculate_aggregate_question_stats(inst_answer, stud_answers_for_q)

      total_match_rate_sum += stats[:match_rate]
      stats
    end

    # 6. Calculate Overall Aggregate Stats
    num_questions = question_breakdown.size
    avg_agreement_pct = num_questions > 0 ? (total_match_rate_sum / num_questions).round(2) : 0

    # 7. Get Team Metadata
    reviewee_team = Team.find_by(id: reviewee_id)

    # Fallback: directly look up a participant whose parent_id is this team
    reviewee_participant = Participant.find_by(parent_id: reviewee_id)

    reviewee_name =
      if reviewee_team&.name.present?
        reviewee_team.name
      elsif reviewee_participant&.user&.full_name.present?
        reviewee_participant.user.full_name
      else
        'Unknown Team'
      end

    render json: {
      reviewee_id: reviewee_id,
      reviewee_name: reviewee_name,
      assignment_id: assignment_id,
      aggregate_stats: {
        total_reviews: student_responses.size,
        avg_agreement_percentage: avg_agreement_pct,
        question_breakdown: question_breakdown
      }
    }, status: :ok
  end

  private

  def get_instructor_participant_id(assignment_id)
    # Get the instructor's user_id from assignments table
    assignment = Assignment.find(assignment_id)
    instructor_id = assignment.instructor_id

    # Find the instructor's participant record for THIS assignment
    # Use parent_id (not assignment_id) which references the assignment
    instructor_participant = Participant.find_by(
      user_id: instructor_id,
      parent_id: assignment_id,
      type: 'AssignmentParticipant'
    )

    # Return the participant_id (used in ResponseMaps)
    instructor_participant&.id
  end

  # Retrieves submitted content (hyperlinks and files) for a team using SubmissionRecord model
  # SubmissionRecord stores both hyperlinks and files with metadata
  # This method queries the SubmissionRecord table for the given team and assignment
  # Gets the latest submissions and reads files from the team's submission directory
  def get_submitted_content(team_id)
    # Find the team
    team = Team.find_by(id: team_id)
    unless team
      Rails.logger.warn("Team not found: #{team_id}")
      return { hyperlinks: [], files: [], error: 'Team not found' }
    end

    # Get assignment from team (AssignmentTeam has assignment through parent_id)
    assignment = team.assignment
    unless assignment
      Rails.logger.warn("Assignment not found for team: #{team_id}")
      return { hyperlinks: [], files: [], error: 'Assignment not found' }
    end

    # Get the most recent hyperlinks from SubmissionRecord (ordered by creation date, latest first)
    submission_records = SubmissionRecord.where(team_id: team_id, assignment_id: assignment.id)
                                         .order(created_at: :desc)

    # Retrieve hyperlinks from SubmissionRecord, excluding those with 'remove' operation
    hyperlinks = build_hyperlinks_from_records(submission_records.hyperlinks.where.not(operation: 'remove'))

    # Retrieve files from the team's submission directory (actual files on filesystem)
    files = get_team_submitted_files(team, assignment)

    {
      hyperlinks: hyperlinks,
      files: files
    }
  rescue StandardError => e
    Rails.logger.error("Error fetching submitted content for team #{team_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { hyperlinks: [], files: [], error: "Content not available: #{e.message}" }
  end

  # Retrieves actual submitted files from the team's submission directory on the filesystem
  # Uses team's directory_num to construct the path where files are stored
  def get_team_submitted_files(team, assignment)
    files = []

    # Return empty if team has no directory number (hasn't submitted yet)
    return [] if team.directory_num.blank?

    # Construct the submission directory path: /submissions/{assignment_id}/{directory_num}/
    base_path = Rails.root.join('submissions', assignment.id.to_s, team.directory_num.to_s)

    # Return empty array if directory doesn't exist
    unless File.exist?(base_path) && File.directory?(base_path)
      Rails.logger.info("Submission directory not found: #{base_path}")
      return []
    end

    # List all files in the submission directory
    Dir.entries(base_path).each do |entry|
      # Skip current directory and parent directory references
      next if ['.', '..'].include?(entry)

      entry_path = File.join(base_path, entry)

      # Only include files, not subdirectories
      next if File.directory?(entry_path)

      begin
        files << {
          filename: entry,
          size: File.size(entry_path),
          size_human: format_file_size(File.size(entry_path)),
          type: File.extname(entry).delete_prefix('.'),
          modified_at: File.mtime(entry_path),
          download_url: "/submitted_content/download?team_id=#{team.id}&filename=#{CGI.escape(entry)}"
        }
      rescue StandardError => e
        Rails.logger.warn("Error processing file #{entry_path}: #{e.message}")
        next
      end
    end

    # Return files sorted alphabetically for consistent ordering
    files.sort_by { |f| f[:filename].downcase }
  rescue StandardError => e
    Rails.logger.error("Error reading submitted files from #{base_path}: #{e.message}")
    []
  end

  # Formats file size from bytes to human-readable format
  def format_file_size(bytes)
    return '0 B' if bytes.zero?

    if bytes < 1024
      "#{bytes} B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(2)} KB"
    else
      "#{(bytes / (1024.0 * 1024.0)).round(2)} MB"
    end
  end

  # Builds hyperlink array from SubmissionRecord hyperlink records
  # Each record contains: content (URL), user (string), created_at, operation
  def build_hyperlinks_from_records(hyperlink_records)
    hyperlink_records.map do |record|
      {
        url: record.content,
        display_text: truncate_url(record.content),
        submitted_by: record.user || 'Unknown',
        submitted_at: record.created_at
      }
    end
  rescue StandardError => e
    Rails.logger.error("Error building hyperlinks from records: #{e.message}")
    []
  end

  # Truncates URL for display purposes (shows first 50 chars, adds ellipsis if longer)
  def truncate_url(url)
    url.length > 50 ? "#{url[0..47]}..." : url
  end

  # Check whether the review has been started, is in progress or is completed
  def get_review_status(response_map_id)
    response = Response.where(map_id: response_map_id)
                       .order(updated_at: :desc)
                       .first

    return 'not_started' if response.nil?

    response.is_submitted ? 'completed' : 'in_progress'
  end

  def get_instructor_review_for_reviewee(assignment_id, reviewee_id)
    instructor_participant_id = get_instructor_participant_id(assignment_id)
    return nil if instructor_participant_id.nil?

    # Find the ResponseMap where instructor reviewed this reviewee
    # ReviewResponseMap has reviewee_id as a Team ID
    instructor_response_map = ResponseMap.find_by(
      reviewer_id: instructor_participant_id,
      reviewee_id: reviewee_id,
      for_calibration: true
    )

    return nil if instructor_response_map.nil? # No review found

    # Get the most recent Response
    Response.where(map_id: instructor_response_map.id)
            .order(updated_at: :desc)
            .first
  end

  # Core logic: Compares instructor and student reviews question by question
  # Returns detailed breakdown per question + summary stats
  # Reusable by both Student Report and Aggregate Report
  def instructor_review_better?(instructor_review, student_review)
    return nil if instructor_review.nil? || student_review.nil?

    # Fetch all answers for both reviews
    instructor_answers = Answer.where(response_id: instructor_review.id)
    student_answers = Answer.where(response_id: student_review.id)

    # Index by item_id for fast O(1) lookup
    instructor_scores = instructor_answers.index_by(&:item_id)
    student_scores = student_answers.index_by(&:item_id)

    question_comparisons = []

    # Statistics Counters
    total_questions = 0
    exact_matches = 0
    close_matches = 0 # Off by 1 or 2 points

    instructor_scores.each do |item_id, instructor_answer|
      student_answer = student_scores[item_id]

      # 1. Get Values (Handle nil student answers gracefully)
      inst_val = instructor_answer.answer.to_i
      stud_val = student_answer&.answer.to_i || 0 # Treats missing answers as 0
      diff = (inst_val - stud_val).abs

      # 2. Update Stats
      if diff == 0
        exact_matches += 1
      elsif diff <= 2
        close_matches += 1
      end
      total_questions += 1

      # 3. Build Question Object (Includes Comments & Text)
      question_comparisons << {
        item_id: item_id,
        question_text: get_question_text(item_id),
        instructor: {
          score: inst_val,
          comments: instructor_answer.comments
        },
        student: {
          score: stud_val,
          comments: student_answer&.comments
        },
        difference: diff,
        direction: student_review_higher?(stud_val, inst_val)
      }
    end

    # 4. Calculate Final Aggregates
    match_rate = total_questions > 0 ? ((exact_matches.to_f / total_questions) * 100).round(2) : 0
    avg_diff = calculate_average_difference(question_comparisons)

    {
      questions: question_comparisons,
      stats: {
        total_questions: total_questions,
        exact_matches: exact_matches,
        close_matches: close_matches,      # Requirement: Off by 1 or 2
        match_rate_percentage: match_rate, # Requirement: Match Rate
        average_difference: avg_diff       # Requirement: Average Difference
      }
    }
  end

  # Helper to safely retrieve question text using Item model
  # Used to prevent crashes if an Item ID is invalid
  def get_question_text(item_id)
    Item.find(item_id).txt
  rescue ActiveRecord::RecordNotFound
    "Question #{item_id}"
  end

  # Determines if the student scored higher, lower, or exact
  def student_review_higher?(student_score, instructor_score)
    if student_score == instructor_score
      'exact'
    elsif student_score > instructor_score
      'over' # Student gave higher score
    else
      'under' # Student gave lower score
    end
  end

  # Computes the mean difference across all questions
  def calculate_average_difference(comparisons)
    return 0 if comparisons.empty?

    total_diff = comparisons.sum { |c| c[:difference] }
    (total_diff.to_f / comparisons.length).round(2)
  end

  # Calculates detailed statistics for a single question across all students
  # Used by calibration_aggregate_report
  def calculate_aggregate_question_stats(instructor_answer, student_answers_list)
    inst_score = instructor_answer.answer.to_i
    total_students = student_answers_list.size

    # Initialize counters
    stats = {
      exact_matches: 0,
      off_by_one: 0,
      off_by_two: 0,
      off_by_three_plus: 0,
      total_student_score: 0
    }

    # Iterate through students to populate counters
    student_answers_list.each do |ans|
      stud_score = ans.answer.to_i
      stats[:total_student_score] += stud_score

      diff = (inst_score - stud_score).abs

      if diff == 0
        stats[:exact_matches] += 1
      elsif diff == 1
        stats[:off_by_one] += 1
      elsif diff == 2
        stats[:off_by_two] += 1
      else
        stats[:off_by_three_plus] += 1
      end
    end

    # Calculate Derived Metrics
    avg_score = total_students > 0 ? (stats[:total_student_score].to_f / total_students).round(2) : 0
    match_rate = total_students > 0 ? ((stats[:exact_matches].to_f / total_students) * 100).round(2) : 0

    {
      item_id: instructor_answer.item_id,
      question_text: get_question_text(instructor_answer.item_id), # Reuses your existing helper
      instructor_score: inst_score,
      avg_student_score: avg_score,
      match_rate: match_rate,
      counts: {
        exact: stats[:exact_matches],
        off_by_one: stats[:off_by_one],
        off_by_two: stats[:off_by_two],
        off_by_three_plus: stats[:off_by_three_plus]
      }
    }
  end
end
