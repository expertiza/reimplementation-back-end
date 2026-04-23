class ReviewMappingsController < ApplicationController
  include Authorization
  before_action :set_assignment
  before_action :authorize

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
      reviewer
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
  def assign_calibration_artifacts
    handler = ReviewMappingHandler.new(@assignment)
    handler.assign_calibration_reviews_round_robin
    render json: { status: "ok", message: "Calibration reviews assigned to all reviewers" }
  end

  def calibration_report
    instructor_map = ReviewResponseMap.find_by!(
      id: params[:id],
      reviewed_object_id: @assignment.id,
      for_calibration: true
    )
    instructor_response = latest_submitted_response_for(instructor_map)
    return render json: { error: "Submitted instructor calibration response not found" }, status: :unprocessable_entity unless instructor_response

    rubric_items = rubric_items_for(instructor_response)
    return render json: { error: "Review rubric not found" }, status: :unprocessable_entity if rubric_items.empty?

    student_responses = submitted_student_responses_for(instructor_map)
    per_item_summary = CalibrationPerItemSummary.build(
      items: rubric_items,
      instructor_response: instructor_response,
      student_responses: student_responses
    )

    render json: {
      map_id: instructor_map.id,
      assignment_id: @assignment.id,
      reviewee_id: instructor_map.reviewee_id,
      rubric_items: rubric_items.map { |item| serialize_item(item) },
      instructor_response: serialize_response(instructor_response),
      student_responses: student_responses.map { |response| serialize_response(response) },
      per_item_summary: per_item_summary,
      submitted_content: submitted_content_for(instructor_map.reviewee)
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Calibration review map not found" }, status: :not_found
  end

  # ===== DELETE =====
  def destroy
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

  def action_allowed?
    return teaching_staff_for_calibration_report? if params[:action] == "calibration_report"

    true
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def teaching_staff_for_calibration_report?
    assignment = Assignment.find_by(id: params[:assignment_id])
    return false unless user_logged_in? && assignment
    return true if assignment.instructor_id == current_user.id

    assignment.course_id.present? && TaMapping.exists?(user_id: current_user.id, course_id: assignment.course_id)
  end

  def latest_submitted_response_for(response_map)
    response_map.responses.where(is_submitted: true).order(updated_at: :desc).first
  end

  def submitted_student_responses_for(instructor_map)
    student_maps = ReviewResponseMap
                   .where(
                     reviewed_object_id: @assignment.id,
                     reviewee_id: instructor_map.reviewee_id,
                     for_calibration: true
                   )
                   .where.not(id: instructor_map.id)

    student_maps.flat_map { |map| map.responses.where(is_submitted: true).to_a }
  end

  def rubric_items_for(response)
    response.questionnaire.items.order(:seq)
  rescue NoMethodError
    []
  end

  def serialize_item(item)
    {
      id: item.id,
      txt: item.txt,
      seq: item.seq,
      question_type: item.question_type,
      weight: item.weight,
      min_score: item.questionnaire.min_question_score,
      max_score: item.questionnaire.max_question_score
    }
  end

  def serialize_response(response)
    {
      id: response.id,
      map_id: response.map_id,
      reviewer_id: response.map.reviewer_id,
      reviewer_name: response.map.reviewer&.fullname,
      is_submitted: response.is_submitted,
      updated_at: response.updated_at,
      answers: response.scores.map do |answer|
        {
          item_id: answer.item_id,
          score: answer.answer,
          comments: answer.comments
        }
      end
    }
  end

  def submitted_content_for(reviewee)
    {
      hyperlinks: reviewee.respond_to?(:hyperlinks) ? reviewee.hyperlinks : [],
      files: SubmissionRecord.files.where(team_id: reviewee.id, assignment_id: @assignment.id).pluck(:content)
    }
  end
end
