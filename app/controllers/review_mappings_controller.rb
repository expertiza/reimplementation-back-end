class ReviewMappingsController < ApplicationController
  before_action :set_assignment

  # ===== STATIC ASSIGNMENT =====
  def assign_round_robin
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_statically(ReviewMappingStrategies::RoundRobinStrategy)
    render json: { status: "ok", message: "Round-robin assignments created" }
  end

  def assign_from_csv
    csv_text = params[:csv].read # file upload
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_from_csv(csv_text)
    render json: { status: "ok", message: "CSV-based assignments created" }
  end

    # POST /assignments/:assignment_id/review_mappings/random
    def assign_random
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_random
    render json: { status: "ok", message: "Random assignments created" }
    end


  # ===== DYNAMIC ASSIGNMENT =====
  def request_review_fewest
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)

    mapping = handler.assign_dynamically(
      ReviewMappingStrategies::LeastReviewedSubmissionStrategy,
      reviewer,
      allow_self_review: false
    )

    if mapping
      render json: { status: "ok", mapping_id: mapping.id }
    else
      render json: { status: "error", message: "No team available or limit reached" }, status: :unprocessable_entity
    end
  end

  def request_review_topic_balance
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)

    mapping = handler.assign_dynamic_topic_fairly(reviewer, k: params[:k].to_i)

    if mapping
      render json: { status: "ok", mapping_id: mapping.id }
    else
      render json: { status: "error", message: "No eligible topic/team available" }, status: :unprocessable_entity
    end
  end

  # ===== CALIBRATION =====
  def set_calibration_artifact
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    calibration_submission = Submission.find(params[:submission_id])
    handler = ReviewMappingHandler.new(@assignment)

    mapping = handler.assign_calibration_review(reviewer, calibration_submission)
    render json: { status: "ok", mapping_id: mapping.id }
  end

  # ===== DELETE =====
  def delete
    handler = ReviewMappingHandler.new(@assignment)
    handler.delete_review_mapping(params[:id])
    render json: { status: "ok", message: "Mapping deleted" }
  end

  def delete_all_for_reviewer
    reviewer = AssignmentParticipant.find(params[:reviewer_id])
    handler = ReviewMappingHandler.new(@assignment)
    handler.delete_all_reviews_for(reviewer)
    render json: { status: "ok", message: "All mappings for reviewer deleted" }
  end

  # ===== INSTRUCTOR GRADING =====
  def grade_review
    mapping = ReviewResponseMap.find(params[:mapping_id])
    handler = ReviewMappingHandler.new(@assignment)

    handler.grade_review(mapping, grade: params[:grade], comment: params[:comment])
    render json: { status: "ok", message: "Review graded" }
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end
end
