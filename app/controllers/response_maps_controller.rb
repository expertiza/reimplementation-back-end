# frozen_string_literal: true

class ResponseMapsController < ApplicationController
  def action_allowed?
    true
  end

  # GET /response_maps?reviewer_user_id=4
  # GET /response_maps?assignment_id=1&reviewer_user_id=4
  # Returns all response maps for a given reviewer user (optionally scoped to one assignment),
  # along with the latest response (draft or submitted) for each map.
  def index
    assignment_id    = params[:assignment_id].present? ? params[:assignment_id].to_i : nil
    reviewer_user_id = params[:reviewer_user_id].to_i

    if reviewer_user_id.zero?
      return render json: { error: 'reviewer_user_id is required' }, status: :bad_request
    end

    # Find all participant records for this user (optionally scoped to one assignment)
    participant_scope = AssignmentParticipant.where(user_id: reviewer_user_id)
    participant_scope = participant_scope.where(parent_id: assignment_id) if assignment_id
    participants = participant_scope.to_a

    if participants.empty?
      return render json: { response_maps: [] }, status: :ok
    end

    map_scope = ResponseMap.where(reviewer_id: participants.map(&:id))
    map_scope = map_scope.where(reviewed_object_id: assignment_id) if assignment_id
    maps = map_scope.to_a

    result = maps.map do |map|
      latest_response = Response.where(map_id: map.id).order(created_at: :desc).first
      team = Team.find_by(id: map.reviewee_id)
      assignment = Assignment.find_by(id: map.reviewed_object_id)

      entry = {
        id: map.id,
        reviewer_id: map.reviewer_id,
        reviewee_id: map.reviewee_id,
        reviewed_object_id: map.reviewed_object_id,
        team_name: team&.name || "Team ##{map.reviewee_id}",
        assignment_name: assignment&.name || "Assignment ##{map.reviewed_object_id}"
      }

      if latest_response
        entry[:latest_response] = {
          id: latest_response.id,
          map_id: latest_response.map_id,
          is_submitted: latest_response.is_submitted,
          created_at: latest_response.created_at,
          updated_at: latest_response.updated_at
        }
      end

      entry
    end

    render json: { response_maps: result }, status: :ok
  end

  # POST /response_maps
  # Finds or creates a ReviewResponseMap for the given assignment, reviewer user, and reviewee team.
  # Params: { assignment_id, reviewer_user_id, reviewee_team_id }
  # Returns: { id, reviewer_id, reviewee_id, reviewed_object_id, reviewer_participant_id }
  def create
    assignment_id    = params[:assignment_id].to_i
    reviewer_user_id = params[:reviewer_user_id].to_i
    reviewee_team_id = params[:reviewee_team_id].to_i

    if assignment_id.zero? || reviewer_user_id.zero? || reviewee_team_id.zero?
      return render json: { error: 'assignment_id, reviewer_user_id, and reviewee_team_id are required' },
                    status: :bad_request
    end

    # Find or create the reviewer's participant record for this assignment
    reviewer_participant = AssignmentParticipant.find_by(user_id: reviewer_user_id, parent_id: assignment_id)
    if reviewer_participant.nil?
      handle = User.find_by(id: reviewer_user_id)&.name || "user_#{reviewer_user_id}"
      reviewer_participant = AssignmentParticipant.create!(
        user_id:    reviewer_user_id,
        parent_id:  assignment_id,
        handle:     handle
      )
    end

    # Find or create the ReviewResponseMap linking reviewer → reviewee team for this assignment
    map = ReviewResponseMap.find_or_create_by!(
      reviewed_object_id: assignment_id,
      reviewer_id:        reviewer_participant.id,
      reviewee_id:        reviewee_team_id
    )

    render json: {
      id:                      map.id,
      reviewer_id:             map.reviewer_id,
      reviewee_id:             map.reviewee_id,
      reviewed_object_id:      map.reviewed_object_id,
      reviewer_participant_id: reviewer_participant.id
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /response_maps/:id
  def destroy
    map = ResponseMap.find_by(id: params[:id])
    return render json: { error: 'ResponseMap not found' }, status: :not_found unless map

    map.destroy!
    render json: { message: 'ResponseMap deleted' }, status: :ok
  end
end
