# frozen_string_literal: true

# Reports live in their own controller per Expertiza convention: a single
# controller responsible only for rendering reports, dispatching to per-report
# actions. Feature controllers (e.g. ReviewMappingsController) should not
# embed report logic, since that violates SRP and hides the code from other
# consumers who need the same information.
class ReportsController < ApplicationController
  include Authorization
  before_action :set_assignment

  # Reports are viewable only by teaching staff for the assignment (instructor
  # of the assignment, the course instructor, or a TA mapped to the course).
  def action_allowed?
    current_user_teaching_staff_of_assignment?(params[:assignment_id])
  end

  # GET /assignments/:assignment_id/reports/calibration/:map_id
  #
  # Returns the comparison data for a single instructor calibration review:
  # the instructor's submitted response, the rubric items, the student
  # calibration responses for the same reviewee, a per-item summary produced
  # by CalibrationPerItemSummary, and the reviewee team's submitted content.
  def calibration
    instructor_map = ReviewResponseMap.find_by!(
      id: params[:map_id],
      reviewed_object_id: @assignment.id,
      for_calibration: true
    )

    instructor_response = instructor_map.latest_submitted_response
    return render_error('Submitted instructor calibration response not found', :unprocessable_entity) unless instructor_response

    rubric_items = instructor_response.rubric_items
    return render_error('Review rubric not found', :unprocessable_entity) if rubric_items.empty?

    student_responses = ReviewResponseMap.peer_calibration_responses_for(instructor_map)

    per_item_summary = CalibrationPerItemSummary.build(
      items: rubric_items,
      instructor_response: instructor_response,
      student_responses: student_responses
    )

    reviewee = instructor_map.reviewee

    render json: {
      map_id: instructor_map.id,
      assignment_id: @assignment.id,
      reviewee_id: instructor_map.reviewee_id,
      rubric_items: rubric_items.map(&:as_calibration_json),
      instructor_response: instructor_response.as_calibration_json,
      student_responses: student_responses.map(&:as_calibration_json),
      per_item_summary: per_item_summary,
      submitted_content: reviewee.respond_to?(:submitted_content) ? reviewee.submitted_content : { hyperlinks: [], files: [] }
    }, status: :ok
  rescue ActiveRecord::RecordNotFound
    render_error('Calibration review map not found', :not_found)
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
