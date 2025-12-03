class ReviewReportsController < ApplicationController
  # GET /review_reports/:assignment_id
  def index
    assignment = Assignment.find(params[:assignment_id])
    # Fetch all review response maps for this assignment
    review_maps = ReviewResponseMap.where(reviewed_object_id: assignment.id)

    report_data = review_maps.map do |map|
      reviewer = map.reviewer.user
      reviewee = map.reviewee # Team
      
      # Get all responses
      responses = Response.where(map_id: map.id).order(created_at: :asc)
      
      rounds = responses.map do |response|
        questionnaire = response.questionnaire_by_answer(response.scores.first)
        assignment_questionnaire = AssignmentQuestionnaire.find_by(assignment_id: assignment.id, questionnaire_id: questionnaire.id)
        round_num = assignment_questionnaire&.used_in_round || 1 # Default to 1 if not specified

        {
          round: round_num,
          calculatedScore: response.aggregate_questionnaire_score,
          maxScore: response.maximum_score,
          reviewVolume: response.volume,
          reviewCommentCount: response.comment_count
        }
      end

      # Use the latest response for general status, but keep rounds data
      latest_response = responses.last
      
      # Calculate reviews done/selected
      reviews_selected = 1 
      reviews_completed = latest_response&.is_submitted ? 1 : 0

      # Calculate score (latest)
      score = latest_response&.aggregate_questionnaire_score
      max_score = latest_response&.maximum_score

      # Calculate volume (latest)
      vol = latest_response&.volume || 0

      # Determine status color
      status = if !latest_response
                 "purple" # No review
               elsif !latest_response.is_submitted
                 "red" # Not completed
               elsif latest_response.is_submitted && map.reviewer_grade.nil?
                 "blue" # Completed, no grade
               elsif map.reviewer_grade
                 "brown" # Grade assigned
               else
                 "green" # Fallback or specific case (No submitted work?)
               end

      {
        id: map.id,
        reviewerName: reviewer.full_name,
        reviewerUsername: reviewer.name,
        reviewerId: reviewer.id,
        reviewsCompleted: reviews_completed,
        reviewsSelected: reviews_selected,
        teamReviewedName: reviewee.name,
        hasConsent: map.reviewer.permission_granted,
        teamReviewedStatus: status,
        calculatedScore: score, # Latest score
        maxScore: max_score,    # Latest max score
        rounds: rounds,         # All rounds data
        reviewComment: latest_response&.additional_comment,
        reviewVolume: vol,
        reviewCommentCount: latest_response&.comment_count || 0,
        assignedGrade: map.reviewer_grade,
        instructorComment: map.reviewer_comment
      }
    end

    # Calculate average volume for the assignment
    total_volume = report_data.sum { |d| d[:reviewVolume] }
    count_volume = report_data.count { |d| d[:reviewVolume] > 0 }
    avg_volume = count_volume > 0 ? total_volume.to_f / count_volume : 0

    render json: {
      reportData: report_data,
      averageVolume: avg_volume
    }
  end

  # PATCH /review_reports/:id/update_grade
  # Updates the grade and comment for a specific review report
  def update_grade
    map = ReviewResponseMap.find(params[:id])
    if map.update(reviewer_grade: params[:assignedGrade], reviewer_comment: params[:instructorComment])
      render json: { message: "Grade updated successfully" }, status: :ok
    else
      render json: { error: "Failed to update grade" }, status: :unprocessable_entity
    end
  end
end
