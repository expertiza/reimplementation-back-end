module TaskOrdering
  class QuizTask < BaseTask
    def task_type
      :quiz
    end

    def questionnaire
      assignment.quiz_questionnaire_for_review_flow
    end

    # Finds or creates QuizResponseMap
    def response_map
      return nil if questionnaire.nil?
      return @response_map if @response_map

      @response_map = QuizResponseMap.find_or_create_by!(
        reviewer_id: participant.id,
        reviewee_id: review_map&.reviewee_id,
        reviewed_object_id: questionnaire.id,
        type: 'QuizResponseMap'
      )
    end
  end
end