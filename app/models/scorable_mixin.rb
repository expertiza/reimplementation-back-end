# frozen_string_literal: true

module ScorableMixin
  # Computes the total points awarded for all scores on the instance
  def calculate_total_score
    # Only count the scorable questions, only when the answer is not nil (we accept nil as
    # answer for scorable questions, and they will not be counted towards the total score)
    sum = 0
    scores.each do |s|
      question = Question.find(s.question_id)
      sum += s.answer * question.weight unless s.answer.nil? || !question.is_a?(ScoredQuestion)
    end
    sum
  end

  # Returns the average score across all of the instances scores as an integer (0-100)
  def average_score
    if maximum_score.zero?
      'N/A'
    else
      ((calculate_total_score.to_f / maximum_score.to_f) * 100).round
    end
  end

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

  def questionnaire_by_answer(answer)
    if answer.nil?
      # Answers can be nil in cases such as "Upload File" being the only question.
      map = ResponseMap.find(map_id)
      # E-1973 either get the assignment from the participant or the map itself
      assignment = if map.is_a? ReviewResponseMap
                     map.assignment
                   else
                     Participant.find(map.reviewer_id).assignment
                   end
      questionnaire = Questionnaire.find(assignment.review_questionnaire_id)
    else
      questionnaire = Question.find(answer.question_id).questionnaire
    end
    questionnaire
  end
end
