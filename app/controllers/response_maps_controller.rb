# frozen_string_literal: true

class ResponseMapsController < ApplicationController
  def action_allowed?
    true
  end

  # Returns all peer-review response maps for a reviewer, excluding quiz maps.
  #
  # Quiz response maps (where +reviewer_id == reviewee_id+) are filtered out so
  # the frontend only receives genuine peer-review assignments. Each entry also
  # carries per-map quiz state (+quiz_taken+, +quiz_questionnaire_id+) so the
  # frontend can gate the "Start Review" button row-by-row without a second
  # request.
  #
  # @param reviewer_user_id [Integer] required; the user whose maps are fetched
  # @param assignment_id [Integer, nil] optional; scopes results to one assignment
  # @return [200] +{ response_maps: [...] }+ each entry contains id, team/assignment
  #   names, quiz state, and the latest {Response} summary if one exists
  # @return [400] if +reviewer_user_id+ is missing
  # GET /response_maps?reviewer_user_id=4
  # GET /response_maps?assignment_id=1&reviewer_user_id=4
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

    result = maps.filter_map do |map|
      # E2619: skip quiz response maps. Quiz maps always have reviewer_id == reviewee_id
      # (the student quizzes themselves). This guard is more reliable than checking whether
      # reviewed_object_id matches an assignment id, because a quiz questionnaire id can
      # coincidentally equal an assignment id and fool the next guard below.
      next if map.reviewer_id == map.reviewee_id

      # Belt-and-suspenders: reviewed_object_id for review maps must reference an assignment.
      assignment = Assignment.find_by(id: map.reviewed_object_id)
      next unless assignment

      latest_response = Response.where(map_id: map.id).order(created_at: :desc).first
      team = Team.find_by(id: map.reviewee_id)

      # E2619: include per-map quiz state so the frontend can gate each review row
      # independently. Each reviewee team owns its own quiz questionnaire, so
      # quiz_taken must be checked per map, not per assignment.
      quiz_questionnaire_id = team&.quiz_questionnaire_id
      quiz_taken = if quiz_questionnaire_id.present?
                     QuizResponseMap
                       .where(reviewer_id: map.reviewer_id, reviewed_object_id: quiz_questionnaire_id)
                       .joins("INNER JOIN responses ON responses.map_id = response_maps.id")
                       .where(responses: { is_submitted: true })
                       .exists?
                   else
                     false
                   end

      entry = {
        id: map.id,
        reviewer_id: map.reviewer_id,
        reviewee_id: map.reviewee_id,
        reviewed_object_id: map.reviewed_object_id,
        team_name: team&.name || "Team ##{map.reviewee_id}",
        assignment_name: assignment&.name || "Assignment ##{map.reviewed_object_id}",
        quiz_questionnaire_id: quiz_questionnaire_id,
        quiz_taken: quiz_taken
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

  # Finds or creates a {ReviewResponseMap} linking a reviewer to a reviewee
  # team for the given assignment. Also ensures the reviewer has an
  # {AssignmentParticipant} record and sets +can_review+ and +can_take_quiz+
  # flags so the student task page shows the quiz requirement.
  #
  # @param assignment_id [Integer] the assignment being reviewed
  # @param reviewer_user_id [Integer] the user who will perform the review
  # @param reviewee_team_id [Integer] the team being reviewed
  # @return [201] the map and participant IDs
  # @return [400] if any required parameter is missing
  # @return [422] if the map or participant cannot be persisted
  # POST /response_maps
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

    # E2619: when a reviewer is assigned, mark them as allowed to review and take the quiz.
    # This gates the quiz/review flow in StudentTask: only participants with can_take_quiz=true
    # will see the quiz requirement on the student tasks page.
    reviewer_participant.update_columns(can_review: true, can_take_quiz: true)

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
