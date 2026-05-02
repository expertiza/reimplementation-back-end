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
  # Renders the calibration comparison report for one instructor map.
  # All assembly logic (rubric items, student responses, per-item score
  # histograms, submitted content) lives in Reports::CalibrationReport,
  # which follows the iterator pattern from Reports::Base — responses are
  # walked one at a time via find_each, never preloaded into an ad-hoc array.
  def calibration
    instructor_map = ReviewResponseMap.find_by!(
      id:                 params[:map_id],
      reviewed_object_id: @assignment.id,
      for_calibration:    true
    )
    render json: Reports::CalibrationReport.new(instructor_map).render, status: :ok
  rescue ActiveRecord::RecordNotFound
    render_error('Calibration review map not found', :not_found)
  rescue Reports::CalibrationReport::InstructorResponseMissing,
         Reports::CalibrationReport::RubricMissing => e
    render_error(e.message, :unprocessable_entity)
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
