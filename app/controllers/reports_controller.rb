# frozen_string_literal: true

class ReportsController < ApplicationController
  REPORT_CLASSES = {
    'review_response_map'           => Reports::ReviewReport,
    'feedback_response_map'         => Reports::FeedbackReport,
    'teammate_review_response_map'  => Reports::TeammateReviewReport,
    'bookmark_rating_response_map'  => Reports::BookmarkRatingReport,
    'answer_tagging'                => Reports::AnswerTaggingReport,
    'basic'                         => Reports::BasicReport
  }.freeze

  # Only TAs, instructors, and admins may view reports.
  def action_allowed?
    current_user_has_ta_privileges?
  end

  # POST /reports/fetch_response_report
  # Returns the requested report as JSON.
  def fetch_response_report
    assignment_id = params[:assignment_id]
    type = params[:type] || 'basic'

    report_class = REPORT_CLASSES[type]
    unless report_class
      return render json: {
        error: "Unknown report type: #{type}. Valid types: #{REPORT_CLASSES.keys.join(', ')}"
      }, status: :unprocessable_entity
    end

    assignment = Assignment.find(assignment_id)
    data = report_class.for_assignment(assignment).run
    render json: { type: type, assignment_id: assignment_id.to_i }.merge(data)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Assignment not found' }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
