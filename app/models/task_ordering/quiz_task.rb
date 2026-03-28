# frozen_string_literal: true

module TaskOrdering
  class QuizTask < BaseTask
    def task_type
      :quiz
    end

    def questionnaire
      assignment.quiz_questionnaire_for_review_flow
    end

    # QuizResponseMap stores the quiz questionnaire id in reviewed_object_id; the base ResponseMap
    # association expects an assignment id, so model validation would fail. Persist without
    # validations (quiz_response_map.rb unchanged).
    def response_map
      return nil if questionnaire.nil?
      return @response_map if @response_map

      attrs = {
        reviewer_id: team_participant.participant_id,
        reviewee_id: review_map&.reviewee_id || 0,
        reviewed_object_id: questionnaire.id,
        type: "QuizResponseMap"
      }

      @response_map = QuizResponseMap.find_by(attrs) || begin
        m = QuizResponseMap.new(attrs)
        m.save!(validate: false)
        m
      end
    end
  end
end
