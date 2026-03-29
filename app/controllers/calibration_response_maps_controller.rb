# frozen_string_literal: true

class CalibrationResponseMapsController < ApplicationController
  # GET /assignments/:assignment_id/calibration_response_maps
  # Lists calibration response maps for the current instructor/TA for this assignment.
  def index
    assignment = Assignment.find_by(id: params[:assignment_id])
    unless assignment
      render json: { error: 'Assignment not found' }, status: :not_found
      return
    end

    reviewer = AssignmentParticipant.find_by(parent_id: assignment.id, user_id: current_user.id)
    unless reviewer
      render json: { error: 'Instructor participant not found for this assignment' }, status: :not_found
      return
    end

    maps = ResponseMap.where(
      reviewed_object_id: assignment.id,
      reviewer_id: reviewer.id,
      for_calibration: true
    ).order(:id)

    render json: maps.as_json(
      only: %i[id reviewed_object_id reviewer_id reviewee_id type for_calibration],
      include: {
        reviewee: { include: { user: {} } }
      }
    ), status: :ok
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

    reviewer = AssignmentParticipant.find_by(parent_id: assignment.id, user_id: current_user.id)
    unless reviewer && map.reviewer_id == reviewer.id
      render json: { error: 'Not authorized for this calibration map' }, status: :forbidden
      return
    end

    existing_response = Response.find_by(map_id: map.id)
    action = existing_response.present? ? 'edit' : 'new'

    render json: {
      map_id: map.id,
      response_id: existing_response&.id,
      redirect_to: "/response/#{action}/#{map.id}"
    }, status: :ok
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

    instructor_participant = AssignmentParticipant.find_or_initialize_by(parent_id: assignment.id,
                                                                         user_id: current_user.id)
    if instructor_participant.new_record?
      instructor_participant.handle = current_user.handle.presence || current_user.name
      instructor_participant.can_submit = false
      instructor_participant.can_review = true
      unless instructor_participant.save
        render json: { error: 'Failed to create instructor participant', details: instructor_participant.errors.full_messages },
               status: :unprocessable_entity
        return
      end
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
    when 'create', 'index', 'begin'
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
end
