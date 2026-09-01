# frozen_string_literal: true

class ReportsController < ApplicationController
  REPORT_CLASSES = {
    'basic' => Reports::BasicReport,
    'review_response_map' => Reports::ReviewReport
  }.freeze

  before_action :set_assignment
  before_action :authorize

  # Only teaching staff (instructor or TA) of the specific assignment may view reports.
  def action_allowed?
    current_user_teaching_staff_of_assignment?(@assignment.id)
  end

  # POST /reports/fetch_report
  # Returns the requested report as JSON.
  def fetch_report
    type = params[:type] || 'basic'

    report_class = REPORT_CLASSES[type]
    unless report_class
      return render json: {
        error: "Unknown report type: #{type}. Valid types: #{REPORT_CLASSES.keys.join(', ')}"
      }, status: :unprocessable_entity
    end

    data = report_class.for_assignment(@assignment).run
    render json: { type: type, assignment_id: @assignment.id }.merge(data)
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
