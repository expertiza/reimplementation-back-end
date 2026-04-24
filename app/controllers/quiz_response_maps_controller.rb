# frozen_string_literal: true

class QuizResponseMapsController < ApplicationController
  def action_allowed?
    true
  end

  # POST /quiz_response_maps
  # Finds or creates a QuizResponseMap for the current student on a given assignment.
  # Params: { assignment_id, reviewer_user_id }
  # Returns: { quiz_map_id, quiz_questionnaire_id, reviewer_participant_id }
  def create
    assignment_id    = params[:assignment_id].to_i
    reviewer_user_id = params[:reviewer_user_id].to_i

    if assignment_id.zero? || reviewer_user_id.zero?
      return render json: { error: 'assignment_id and reviewer_user_id are required' },
                    status: :bad_request
    end

    assignment = Assignment.find_by(id: assignment_id)
    return render json: { error: 'Assignment not found' }, status: :not_found unless assignment

    # Find the quiz questionnaire linked to this assignment
    quiz_questionnaire = assignment.assignment_questionnaires
                                   .joins(:questionnaire)
                                   .where(questionnaires: { questionnaire_type: %w[Quiz QuizQuestionnaire] })
                                   .first
                                   &.questionnaire

    return render json: { error: 'No quiz questionnaire assigned to this assignment' },
                  status: :unprocessable_entity unless quiz_questionnaire

    # Find or create the reviewer's participant record for this assignment
    reviewer_participant = AssignmentParticipant.find_by(user_id: reviewer_user_id,
                                                         parent_id: assignment_id)
    if reviewer_participant.nil?
      handle = User.find_by(id: reviewer_user_id)&.name || "user_#{reviewer_user_id}"
      reviewer_participant = AssignmentParticipant.create!(
        user_id:   reviewer_user_id,
        parent_id: assignment_id,
        handle:    handle
      )
    end

    # Find or create the QuizResponseMap
    # reviewed_object_id = quiz questionnaire id (as per QuizResponseMap convention)
    # reviewee_id = reviewer's own participant id (taking quiz for themselves)
    map = QuizResponseMap.find_by(
      reviewed_object_id: quiz_questionnaire.id,
      reviewer_id:        reviewer_participant.id,
      reviewee_id:        reviewer_participant.id
    )

    unless map
      map = QuizResponseMap.new(
        reviewed_object_id: quiz_questionnaire.id,
        reviewer_id:        reviewer_participant.id,
        reviewee_id:        reviewer_participant.id
      )
      map.save(validate: false)
      unless map.persisted?
        return render json: { error: map.errors.full_messages.to_sentence.presence || 'Failed to create quiz response map' },
                      status: :unprocessable_entity
      end
    end

    render json: {
      quiz_map_id:             map.id,
      quiz_questionnaire_id:   quiz_questionnaire.id,
      reviewer_participant_id: reviewer_participant.id
    }, status: :created
  rescue ActiveRecord::RecordInvalid, StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
