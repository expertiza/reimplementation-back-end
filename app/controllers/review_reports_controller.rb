# frozen_string_literal: true

# Handles instructor actions on review reports, currently grade/comment saving.
#
# PATCH /review_reports/:id
#   :id — ReviewResponseMap id. We look up the map to get the reviewer's
#   participant_id, then upsert a ReviewGrade record for that participant.
#   One ReviewGrade per reviewer per assignment (matches old schema).
class ReviewReportsController < ApplicationController
  before_action :set_map
  before_action :authorize

  def action_allowed?
    current_user_teaching_staff_of_assignment?(@map.assignment.id)
  end

  # PATCH /review_reports/:id
  def update
    grade   = params[:assignedGrade].presence&.to_f
    comment = params[:instructorComment].to_s.strip

    review_grade = ReviewGrade.find_or_initialize_by(participant_id: @map.reviewer_id)
    review_grade.assign_attributes(
      grade_for_reviewer:   grade,
      comment_for_reviewer: comment.presence,
      grader_id:            current_user.id
    )

    if review_grade.save
      render json: {
        participant_id:       @map.reviewer_id,
        grade_for_reviewer:   review_grade.grade_for_reviewer,
        comment_for_reviewer: review_grade.comment_for_reviewer
      }, status: :ok
    else
      render json: { error: review_grade.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def set_map
    @map = ReviewResponseMap.includes(:assignment).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Review mapping not found' }, status: :not_found
  end
end
