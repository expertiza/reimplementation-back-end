# frozen_string_literal: true

# Dispatches report requests to the appropriate report class.
# Authorized for admins and teaching staff of the assignment.
# POST /reports/generate_report
class ReportsController < ApplicationController
  REPORT_CLASSES = {
    'basic' => Reports::BasicReport,
    'review_response_map' => Reports::ReviewReport,
    'teammate_review_response_map' => Reports::TeammateReviewReport
  }.freeze

  before_action :set_assignment
  before_action :authorize

  def action_allowed?
    current_user_has_admin_privileges? ||
      current_user_teaching_staff_of_assignment?(@assignment.id)
  end

  # POST /reports/generate_report
  # Builds and returns the requested report as JSON.
  def generate_report
    type = params[:type] || 'basic'

    report_class = REPORT_CLASSES[type]
    unless report_class
      return render json: {
        error: "Unknown report type: #{type}. Valid types: #{REPORT_CLASSES.keys.join(', ')}"
      }, status: :unprocessable_entity
    end

    data = report_class.for_assignment(@assignment).run
    render json: { type: type, assignment_id: @assignment.id, assignment_name: @assignment.name }.merge(data)
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Assignment not found' }, status: :not_found
  end
end
