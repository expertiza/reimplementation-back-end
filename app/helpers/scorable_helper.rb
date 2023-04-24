# frozen_string_literal: true

module  ScorableHelper

  # Returns the maximum possible total score for all scores on the instance
  def maximum_score
    # Only count the scorable questions, only when the answer is not nil (we accept nil as
    # answer for scorable questions, and they will not be counted towards the total score)
    total_weight = 0
    scores.each do |s|
      question = Question.find(s.question_id)
      total_weight += question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    questionnaire = if scores.empty?
                      questionnaire_by_answer(nil)
                    else
                      questionnaire_by_answer(scores.first)
                    end
    total_weight * questionnaire.max_question_score
  end

end
