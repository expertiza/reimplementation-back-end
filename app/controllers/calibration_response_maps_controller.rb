# frozen_string_literal: true

# app/services is not always autoloaded in api_only apps; load explicitly so the constant exists at runtime.
require_relative '../services/calibration_submitted_content'

class CalibrationResponseMapsController < ApplicationController
  include EnsuresInstructorAssignmentParticipant
  # GET /assignments/:assignment_id/calibration_response_maps
  # Lists calibration response maps for the current instructor/TA for this assignment.
  def index
    assignment = Assignment.find_by(id: params[:assignment_id])
    unless assignment
      render json: { error: 'Assignment not found' }, status: :not_found
      return
    end

    reviewer = ensure_instructor_assignment_participant!(assignment)
    unless reviewer
      render json: { error: 'Failed to create instructor participant for this assignment',
                     details: @instructor_participant_save_errors },
            status: :unprocessable_entity
      return
    end

    maps = ResponseMap.where(
      reviewed_object_id: assignment.id,
      reviewer_id: reviewer.id,
      for_calibration: true
    ).order(:id)

    payload = maps.map { |m| calibration_map_list_entry(m) }
    render json: payload, status: :ok
  end

  # POST /assignments/:assignment_id/calibration_response_maps/:id/begin
  # Returns routing info so the client can open the calibration review editor for the map.
  def begin
    assignment = Assignment.find_by(id: params[:assignment_id])
    unless assignment
      render json: { error: 'Assignment not found' }, status: :not_found
      return
    end

    map = ResponseMap.find_by(id: params[:id], reviewed_object_id: assignment.id, for_calibration: true)
    unless map
      render json: { error: 'Calibration response map not found' }, status: :not_found
      return
    end

    reviewer = ensure_instructor_assignment_participant!(assignment)
    unless reviewer
      render json: { error: 'Failed to create instructor participant for this assignment',
                     details: @instructor_participant_save_errors },
            status: :unprocessable_entity
      return
    end
    unless map.reviewer_id == reviewer.id
      render json: { error: 'Not authorized for this calibration map' }, status: :forbidden
      return
    end

    existing_response = Response.find_by(map_id: map.id)

    render json: {
      map_id: map.id,
      response_id: existing_response&.id,
      # SPA: same review UI as linked from the assignment editor (Begin / View / Edit).
      redirect_to: "/assignments/edit/#{assignment.id}/calibration/#{map.id}/review"
    }, status: :ok
  end

  # POST /assignments/:assignment_id/calibration_response_maps/:id/instructor_response
  # Body JSON: { answers: [{ item_id, answer, comments }], additional_comment, is_submitted }
  def save_instructor_response
    assignment = Assignment.find_by(id: params[:assignment_id])
    unless assignment
      render json: { error: 'Assignment not found' }, status: :not_found
      return
    end

    map = ResponseMap.find_by(id: params[:id], reviewed_object_id: assignment.id, for_calibration: true)
    unless map
      render json: { error: 'Calibration response map not found' }, status: :not_found
      return
    end

    reviewer = ensure_instructor_assignment_participant!(assignment)
    unless reviewer
      render json: { error: 'Failed to create instructor participant for this assignment',
                     details: @instructor_participant_save_errors },
            status: :unprocessable_entity
      return
    end
    unless map.reviewer_id == reviewer.id
      render json: { error: 'Not authorized for this calibration map' }, status: :forbidden
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

    review_round = assignment.review_round_for_rubric(questionnaire)

    payload = instructor_response_save_params
    answers_in = payload[:answers]
    unless answers_in.is_a?(Array)
      render json: { error: 'answers must be an array' }, status: :bad_request
      return
    end

    response = Response.where(map_id: map.id).order(updated_at: :desc).first
    if response&.is_submitted
      render json: { error: 'This review has already been submitted and cannot be changed.' }, status: :unprocessable_entity
      return
    end

    response ||= Response.create!(map_id: map.id, round: review_round, is_submitted: false)

    valid_item_ids = questionnaire.items.pluck(:id).to_set

    ActiveRecord::Base.transaction do
      answers_in.each do |a|
        item_id = a[:item_id].to_i
        next if item_id <= 0
        next unless valid_item_ids.include?(item_id)

        ans = Answer.find_or_initialize_by(response_id: response.id, item_id: item_id)
        if a.key?(:answer)
          ans.answer = a[:answer].nil? ? nil : a[:answer].to_i
        end
        ans.comments = a[:comments].to_s if a.key?(:comments)
        ans.save!
      end

      if payload[:additional_comment_provided]
        response.additional_comment = payload[:additional_comment].to_s
      end
      if payload[:is_submitted_provided]
        response.is_submitted = ActiveModel::Type::Boolean.new.cast(payload[:is_submitted])
      end
      response.round = review_round if response.round.blank?
      response.save!
    end

    render json: calibration_instructor_response_json(response.reload), status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # POST /assignments/:assignment_id/calibration_response_maps
  # Body: { username: "some_user" }
  #
  # Ensures the target user exists, ensures they are an AssignmentParticipant for the assignment (idempotent),
  # and ensures the current instructor/TA has a ResponseMap to that participant with for_calibration=true.
  def create
    assignment = Assignment.find_by(id: params[:assignment_id])
    unless assignment
      render json: { error: 'Assignment not found' }, status: :not_found
      return
    end

    username = params[:username].to_s.strip
    if username.empty?
      render json: { error: 'username is required' }, status: :unprocessable_entity
      return
    end

    user = User.find_by(name: username)
    unless user
      render json: { error: "Unknown username: #{username}" }, status: :not_found
      return
    end

    participant = AssignmentParticipant.find_or_initialize_by(parent_id: assignment.id, user_id: user.id)
    if participant.new_record?
      participant.handle = user.handle.presence || user.name
      unless participant.save
        render json: { error: 'Failed to create participant', details: participant.errors.full_messages },
               status: :unprocessable_entity
        return
      end
    end
    # Idempotent: ensures student has a one-person team when has_teams is false (required for submissions).
    assignment.ensure_solo_submission_team!(participant)

    instructor_participant = ensure_instructor_assignment_participant!(assignment)
    unless instructor_participant
      render json: { error: 'Failed to create instructor participant', details: @instructor_participant_save_errors },
             status: :unprocessable_entity
      return
    end

    response_map = ResponseMap.find_or_create_by!(
      reviewed_object_id: assignment.id,
      reviewer_id: instructor_participant.id,
      reviewee_id: participant.id
    )
    response_map.update!(for_calibration: true) unless response_map.for_calibration

    team = participant.team
    team_payload =
      if team
        {
          id: team.id,
          name: team.name,
          type: team.type,
          hyperlinks: team.respond_to?(:hyperlinks) ? team.hyperlinks : []
        }
      else
        # Some clients assume a team-like object exists and read `team.hyperlinks` without nil checks.
        { id: nil, name: nil, type: nil, hyperlinks: [] }
      end

    render json: {
      participant: participant.as_json(include: { user: {} }),
      response_map: response_map.as_json(only: %i[id reviewed_object_id reviewer_id reviewee_id type for_calibration]),
      team: team_payload
    }, status: :created
  end

  def action_allowed?
    case params[:action]
    when 'create', 'index', 'begin', 'save_instructor_response'
      assignment = Assignment.find_by(id: params[:assignment_id])
      unless assignment
        render json: { error: 'Assignment not found' }, status: :not_found
        return false
      end
      current_user_teaching_staff_of_assignment?(assignment.id)
    else
      false
    end
  end

  private

  def calibration_map_list_entry(map)
    base = map.as_json(
      only: %i[id reviewed_object_id reviewer_id reviewee_id type for_calibration],
      include: {
        reviewee: { include: { user: {} } }
      }
    )
    reviewee = map.reviewee
    base['participant_name'] = calibration_participant_display_name(reviewee)
    base['submitted_content'] =
      reviewee.is_a?(AssignmentParticipant) ? ::CalibrationSubmittedContent.for_participant(reviewee) : { hyperlinks: [], files: [] }
    base['review_status'] = calibration_map_review_status(map)
    base
  end

  def calibration_participant_display_name(participant)
    return '' unless participant&.user

    participant.user.full_name.presence || participant.user.name
  end

  def calibration_map_review_status(map)
    r = Response.where(map_id: map.id).order(updated_at: :desc).first
    return 'not_started' unless r

    r.is_submitted ? 'submitted' : 'in_progress'
  end

  # JSON clients send { answers: [{ item_id, answer, comments }, ...] }. Nested `permit` on arrays
  # is easy to misconfigure and can drop every row; parse explicitly and still validate item_ids later.
  def instructor_response_save_params
    raw = params.to_unsafe_h
    answers_param = raw['answers'] || raw[:answers]
    answers_list = normalize_instructor_answers_param(answers_param)

    answers = answers_list.map do |row|
      h = row.is_a?(ActionController::Parameters) ? row.to_unsafe_h : row
      h = h.with_indifferent_access
      out = { item_id: h[:item_id].to_i }
      out[:answer] = h[:answer] if h.key?(:answer)
      out[:comments] = h[:comments] if h.key?(:comments)
      out
    end

    {
      answers: answers,
      additional_comment: raw['additional_comment'] || raw[:additional_comment],
      additional_comment_provided: raw.key?('additional_comment') || raw.key?(:additional_comment),
      is_submitted: raw['is_submitted'] || raw[:is_submitted],
      is_submitted_provided: raw.key?('is_submitted') || raw.key?(:is_submitted)
    }
  end

  def normalize_instructor_answers_param(value)
    return [] if value.blank?

    if defined?(ActionController::Parameters) && value.is_a?(ActionController::Parameters)
      return normalize_instructor_answers_param(value.to_unsafe_h)
    end

    return value if value.is_a?(Array)

    # Rare: single object or indexed hash from a client
    if value.is_a?(Hash)
      h = value.with_indifferent_access
      return [value] if h.key?(:item_id) || h.key?(:answer) || h.key?(:comments)

      return h.values
    end

    []
  end

  def calibration_instructor_response_json(response)
    {
      response_id: response.id,
      additional_comment: response.additional_comment.to_s,
      is_submitted: response.is_submitted,
      updated_at: response.updated_at,
      answers: response.scores.includes(:item).map do |s|
        { item_id: s.item_id, answer: s.answer, comments: s.comments.to_s }
      end
    }
  end
end
