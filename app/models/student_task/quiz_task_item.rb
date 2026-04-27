# frozen_string_literal: true

class StudentTask::QuizTaskItem < StudentTask::BaseTaskItem
  def task_type
    :quiz
  end

  def questionnaire
    assignment.quiz_questionnaire_for_review_flow
  end

  def response_map
    return @response_map if @response_map

    existing_map = QuizResponseMap.find_by(
      reviewer_id: team_participant.participant_id,
      reviewee_id: review_map&.reviewee_id || 0
    )
    return @response_map = existing_map if existing_map

    return nil if questionnaire.nil?

    attributes = {
      reviewer_id: team_participant.participant_id,
      reviewee_id: review_map&.reviewee_id || 0,
      reviewed_object_id: questionnaire.id,
      type: "QuizResponseMap"
    }

    @response_map = QuizResponseMap.new(attributes).tap { |map| map.save!(validate: false) }
  end
end
