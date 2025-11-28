# app/controllers/calibration_controller.rb

class CalibrationController < ApplicationController 

  # GET /assignments/:assignment_id/calibration_submissions
  def get_instructor_calibration_submissions
    assignment_id = params[:assignment_id] 

    # Get the instructor's participant ID for this assignment
    instructor_participant_id = get_instructor_participant_id(assignment_id)

    # Find calibration submissions where the INSTRUCTOR is the REVIEWER
    calibration_submissions = ResponseMap.where(
      reviewed_object_id: assignment_id,
      reviewer_id: instructor_participant_id, 
      to_calibrate: true  
    )

    # Get the details for each calibration submission
    submissions = calibration_submissions.map do |response_map|

      # Find the participant who is being reviewed
      reviewee = Participant.find_by(id: response_map.reviewee_id)

      # Get the submission content for that team
      submitted_content = get_submitted_content(reviewee.parent_id)

      # Check if the review has been started
      review_status = get_review_status(response_map.id)

      {
        participant_name: reviewee.name,
        reviewee_id: response_map.reviewee_id,
        response_map_id: response_map.id,
        submitted_content: submitted_content,
        review_status: review_status
      }
    end

    render json: { calibration_submissions: submissions }, status: :ok
  end


  # GET /calibration/student_comparison
  def compare_student_calibration_reviews
    # When Student wants to see their calibration comparison with the Instructor review

    student_participant_id = params[:student_participant_id]
    assignment_id = params[:assignment_id]
    
    # Find all calibration reviews this student did
    student_calibration_maps = ResponseMap.where(
      reviewer_id: student_participant_id,
      reviewed_object_id: assignment_id,
      to_calibrate: true
    )
    
    # For each calibration review, compare the student's review and the instructor's review
    comparisons = student_calibration_maps.map do |student_response_map|
      # Get the student's review
      student_review = Response.where(response_map_id: student_response_map.id)
                               .order(updated_at: :desc)
                               .first
      
      # Get the instructor's review of the SAME reviewee
      instructor_review = get_instructor_review_for_reviewee(
        assignment_id,
        student_response_map.reviewee_id
      )
      
      # Compare them 
      comparison = if instructor_review && student_review
                     compare_two_reviews(instructor_review, student_review)
                   else
                     { error: "Missing review data" }
                   end
      
      {
        reviewee_name: Participant.find(student_response_map.reviewee_id).name,
        reviewee_id: student_response_map.reviewee_id,
        comparison: comparison
      }
    end
    
    render json: { 
      student_participant_id: student_participant_id,
      calibration_comparisons: comparisons 
    }, status: :ok
  end

  # GET /calibration/assignments/:assignment_id/students/:student_participant_id/summary
  # For a given student + assignment, returns info about each submission
  # they calibrated:
  #  - all reviewers (team members who submitted the work)
  #  - all hyperlinks submitted by that user/team
  #  - the to_calibrate flag for that calibration review
  def summary
    student_participant_id = params[:student_participant_id]
    assignment_id          = params[:assignment_id]

    # All calibration maps for this student on this assignment
    student_calibration_maps = ResponseMap.where(
      reviewer_id:        student_participant_id,
      reviewed_object_id: assignment_id,
      to_calibrate:       true
    )

    submissions = student_calibration_maps.map do |student_response_map|
      # The submission being calibrated belongs to this reviewee participant
      reviewee = Participant.find_by(id: student_response_map.reviewee_id)
      next unless reviewee

      # Team members (there may be multiple if the submission is by a team)
      team_members = Participant.where(
        assignment_id: assignment_id,
        parent_id:     reviewee.parent_id
      )

      reviewers = team_members.map do |member|
        {
          participant_id: member.id,
          full_name:      member.name
        }
      end

      # Submitted content for this team/user (hyperlinks + files)
      submitted_content = get_submitted_content(reviewee.parent_id)
      hyperlinks = submitted_content[:hyperlinks] || []

      {
        reviewee_participant_id: reviewee.id,
        reviewee_team_id:        reviewee.parent_id,
        reviewers:               reviewers,
        hyperlinks:              hyperlinks,
        to_calibrate:            student_response_map.to_calibrate
      }
    end.compact

    render json: {
      student_participant_id: student_participant_id,
      assignment_id:          assignment_id,
      submissions:            submissions
    }, status: :ok
  end

  # GET /calibration/assignments/:assignment_id/report/:reviewee_id
  # Calculates aggregate statistics for the class on a specific calibration assignment
  def calibration_aggregate_report
    assignment_id = params[:assignment_id]
    reviewee_id   = params[:reviewee_id]

    # 1. Get the Instructor's Review 
    instructor_review = get_instructor_review_for_reviewee(assignment_id, reviewee_id)

    if instructor_review.nil?
      render json: { error: "Instructor review not found. Cannot generate report." }, status: :not_found
      return
    end

    # 2. Find ALL student calibration reviews for this specific reviewee
    student_calibration_maps = ResponseMap.where(
      reviewed_object_id: assignment_id,
      reviewee_id: reviewee_id,
      to_calibrate: true
    )

    # Exclude the instructor's own map to ensure we only get students
    instructor_participant_id = get_instructor_participant_id(assignment_id)
    student_calibration_maps = student_calibration_maps.where.not(reviewer_id: instructor_participant_id)

    # 3. Collect the latest submitted Response for each student
    student_responses = student_calibration_maps.map do |map|
      Response.where(response_map_id: map.id).order(updated_at: :desc).first
    end.compact

    # 4. Process Question Breakdown
    # Get all answers from the instructor to identify the questions
    instructor_answers = Answer.where(response_id: instructor_review.id)
    
    question_breakdown = []
    total_match_rate_sum = 0

    instructor_answers.each do |inst_answer|
      question_id = inst_answer.question_id
      
      # Try to find question text, fallback if missing
      begin
        question_text = Questionnaire.find(question_id).txt
      rescue ActiveRecord::RecordNotFound
        question_text = "Question #{question_id}"
      end

      # Find all student answers for THIS specific question
      student_answers_for_q = student_responses.map do |resp|
        Answer.find_by(response_id: resp.id, question_id: question_id)
      end.compact

      # Calculate Stats for this question
      student_count_for_q = student_answers_for_q.size
      
      if student_count_for_q > 0
        # Average Student Score
        total_score = student_answers_for_q.sum(&:answer)
        avg_student_score = (total_score.to_f / student_count_for_q).round(2)

        # Match Rate (How many students exactly matched the instructor?)
        matches = student_answers_for_q.count { |ans| ans.answer == inst_answer.answer }
        match_rate = ((matches.to_f / student_count_for_q) * 100).round(2)
      else
        avg_student_score = 0
        match_rate = 0
      end

      total_match_rate_sum += match_rate

      question_breakdown << {
        question_id: question_id,
        question_text: question_text,
        instructor_score: inst_answer.answer,
        avg_student_score: avg_student_score,
        match_rate: match_rate
      }
    end

    # 5. Calculate Overall Aggregate Stats
    num_questions = question_breakdown.size
    avg_agreement_pct = num_questions > 0 ? (total_match_rate_sum / num_questions).round(2) : 0

    # 6. Build Final JSON Response
    reviewee = Participant.find_by(id: reviewee_id)
    reviewee_name = reviewee ? reviewee.name : "Unknown Reviewee"

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
    instructor_participant = Participant.find_by(
      user_id: instructor_id,
      assignment_id: assignment_id
    )
    
    # Return the participant_id (used in ResponseMaps)
    instructor_participant.id
  end

  #Need to updated once the pull request is complete!
  def get_submitted_content(parent_id)
    #The pull request for SubmittedContentController is not merged yet
    SubmittedContentController.get_content_for_team(parent_id)
  rescue => e
    # Handle case where SubmittedContentController isn't ready
    Rails.logger.error("Error fetching submitted content: #{e.message}")
    { hyperlinks: [], files: [], error: "Content not available" }
  end
  
  #Check whether the review has been started, is in progress or is completed
  def get_review_status(response_map_id) 
    response = Response.where(response_map_id: response_map_id)
                       .order(updated_at: :desc)
                       .first
    
    return 'not_started' if response.nil?
    response.is_submitted ? 'completed' : 'in_progress'
  end
  
  def get_instructor_review_for_reviewee(assignment_id, reviewee_id)
    instructor_participant_id = get_instructor_participant_id(assignment_id)
    
    # Find the ResponseMap where instructor reviewed this reviewee
    instructor_response_map = ResponseMap.find_by(
      reviewer_id: instructor_participant_id,
      reviewee_id: reviewee_id,
      for_calibration: true
    )
    
    return nil if instructor_response_map.nil? # No review found
    
    # Get the most recent Response
    Response.where(response_map_id: instructor_response_map.id)
            .order(updated_at: :desc)
            .first
  end



  #Compare instructor and student reviews question by question
  def compare_two_reviews(instructor_review, student_review)
    return nil if instructor_review.nil? || student_review.nil? 
    
    # Get all answers (scores for each question) from both reviews
    instructor_answers = Answer.where(response_id: instructor_review.id)
    student_answers = Answer.where(response_id: student_review.id)
    
    # Grouping by question for easy comparison
    instructor_scores = instructor_answers.index_by(&:question_id)
    student_scores = student_answers.index_by(&:question_id)
    
    question_comparisons = []
    
    instructor_scores.each do |question_id, instructor_answer|
      student_answer = student_scores[question_id] #Get Student's Answer for Same Question
      question = Questionnaire.find(question_id) #Get Question Details
      
      question_comparisons << {
        question_id: question_id,
        question_text: question.name,
        instructor_score: instructor_answer.answer,
        student_score: student_answer&.answer,
        matches: instructor_answer.answer == student_answer&.answer
      }
    end
    
    {
      questions: question_comparisons,
      agreement_percentage: calculate_agreement(question_comparisons)
    }
  end

  #Calculate what percentage of questions the student got right
  def calculate_agreement(comparisons)
    return 0 if comparisons.empty?
    matches = comparisons.count { |c| c[:matches] }
    (matches.to_f / comparisons.length * 100).round(2) #Calculate Percentage
  end

  # Serialize a review into a structure for JSON output
  def serialize_review(review)
    return nil unless review

    answers = Answer.where(response_id: review.id)

    {
      id:          review.id,
      updated_at:  review.updated_at,
      is_submitted: review.is_submitted,
      answers: answers.map do |ans|
        {
          question_id: ans.question_id,
          score:       ans.answer,
          comments:    ans.comments
        }
      end
    }
  end

end