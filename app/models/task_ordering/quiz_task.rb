# frozen_string_literal: true

module TaskOrdering
  class QuizTask < BaseTask
    def task_type
      :quiz
    end

    def questionnaire
      assignment.quiz_questionnaire_for_review_flow
    end

    def response_map
      return @response_map if @response_map

      # First: check if a QuizResponseMap already exists for this reviewer/reviewee
      existing = QuizResponseMap.find_by(
        reviewer_id: team_participant.participant_id,
        reviewee_id: review_map&.reviewee_id || 0
      )
      return @response_map = existing if existing

      # Second: if no existing map, create one — but only if a questionnaire exists
      return nil if questionnaire.nil?

      attrs = {
        reviewer_id: team_participant.participant_id,
        reviewee_id: review_map&.reviewee_id || 0,
        reviewed_object_id: questionnaire.id,
        type: "QuizResponseMap"
      }

      @response_map = QuizResponseMap.new(attrs).tap { |m| m.save!(validate: false) }
    end
  end
end