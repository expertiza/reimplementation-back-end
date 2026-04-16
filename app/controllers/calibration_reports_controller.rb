# frozen_string_literal: true

require_relative '../services/calibration_per_item_summary'
require_relative '../services/calibration_submitted_content'

# GET /assignments/:assignment_id/calibration_reports/:id
# JSON for instructor calibration comparison: gold-standard review vs student calibrator reviews + per-item summary.
class CalibrationReportsController < ApplicationController
  include EnsuresInstructorAssignmentParticipant

  def show
    assignment = Assignment.find_by(id: params[:assignment_id])
    unless assignment
      render json: { error: 'Assignment not found' }, status: :not_found
      return
    end

    instructor_participant = ensure_instructor_assignment_participant!(assignment)
    unless instructor_participant
      render json: { error: 'Failed to create instructor participant for this assignment',
                     details: @instructor_participant_save_errors },
            status: :unprocessable_entity
      return
    end

    instructor_map = ResponseMap.find_by(
      id: params[:id],
      reviewed_object_id: assignment.id,
      for_calibration: true,
      reviewer_id: instructor_participant.id
    )

    unless instructor_map
      render json: { error: 'Calibration response map not found' }, status: :not_found
      return
    end

    reviewee = instructor_map.reviewee
    unless reviewee.is_a?(AssignmentParticipant)
      render json: { error: 'Invalid reviewee for calibration map' }, status: :unprocessable_entity
      return
    end

    questionnaire = assignment.review_rubric_questionnaire

    unless questionnaire
      render json: {
        error: 'No questionnaire configured for this assignment. Open the assignment editor, Rubrics tab, ' \
               'and link a review questionnaire (round 1 for single-round reviews).'
      }, status: :unprocessable_entity
      return
    end

    rubric_items = questionnaire.items.order(:seq)

    # Do not use Item#as_json here: Item overrides `as_json` and drops `id`, which breaks the report UI.
    rubric_json = rubric_items.map do |item|
      {
        id: item.id,
        txt: item.txt,
        weight: item.weight,
        seq: item.seq,
        question_type: item.question_type,
        min_label: item.min_label,
        max_label: item.max_label,
        break_before: item.break_before
      }
    end

    submitted_instructor = Response.where(map_id: instructor_map.id, is_submitted: true).order(updated_at: :desc).first
    latest_instructor = Response.where(map_id: instructor_map.id).order(updated_at: :desc).first
    instructor_payload = serialize_response(latest_instructor)

    instructor_scores = {}
    gold_source = submitted_instructor || latest_instructor
    gold_source&.scores&.each do |a|
      instructor_scores[a.item_id] = a.answer
    end

    student_maps = ResponseMap.where(
      reviewed_object_id: assignment.id,
      reviewee_id: reviewee.id,
      for_calibration: true
    ).where.not(id: instructor_map.id)

    student_rows = []
    student_responses = []

    student_maps.each do |sm|
      r = Response.where(map_id: sm.id, is_submitted: true).order(updated_at: :desc).first
      next unless r

      payload = serialize_response(r)
      reviewer = sm.reviewer
      payload[:reviewer_name] = reviewer&.user&.full_name.presence || reviewer&.user&.name || "participant_#{reviewer&.id}"
      payload[:response_map_id] = sm.id
      student_responses << payload
      student_rows << { answers: payload[:answers] }
    end

    per_item_summary = ::CalibrationPerItemSummary.build(rubric_items, instructor_scores, student_rows)

    render json: {
      assignment_id: assignment.id,
      response_map_id: instructor_map.id,
      team_id: reviewee.team&.id,
      team_name: reviewee.team&.name,
      participant_name: reviewee.user&.full_name.presence || reviewee.user&.name,
      questionnaire_id: questionnaire.id,
      questionnaire_name: questionnaire.name,
      review_round: assignment.assignment_questionnaires.find_by(questionnaire_id: questionnaire.id)&.used_in_round,
      rubric: rubric_json,
      instructor_response: instructor_payload,
      student_responses: student_responses,
      per_item_summary: per_item_summary,
      submitted_content: ::CalibrationSubmittedContent.for_participant(reviewee),
      score_scale: {
        min: questionnaire.min_question_score,
        max: questionnaire.max_question_score
      }
    }, status: :ok
  end

  def action_allowed?
    assignment = Assignment.find_by(id: params[:assignment_id])
    unless assignment
      render json: { error: 'Assignment not found' }, status: :not_found
      return false
    end

    current_user_teaching_staff_of_assignment?(assignment.id)
  end

  private

  def serialize_response(response)
    return nil unless response

    answers = response.scores.includes(:item).map do |s|
      {
        item_id: s.item_id,
        answer: s.answer,
        comments: s.comments.to_s
      }
    end

    {
      response_id: response.id,
      additional_comment: response.additional_comment.to_s,
      is_submitted: response.is_submitted,
      updated_at: response.updated_at,
      answers: answers
    }
  end
end
