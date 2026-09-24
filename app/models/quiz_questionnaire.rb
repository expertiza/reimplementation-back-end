# frozen_string_literal: true

class QuizQuestionnaire < Questionnaire
  after_initialize :post_initialization
  @print_name = 'Quiz Rubric'

  def post_initialization
    self.display_type = 'Quiz'
  end

  def symbol
    'quiz'.to_sym
  end

  def get_assessments_for(participant)
    participant.quizzes_taken
  end

  # Returns true if anyone has already taken this quiz (prevents further edits).
  def taken_by_anyone?
    ResponseMap.where(reviewed_object_id: id, type: 'QuizResponseMap').any?
  end

  # Returns true if the given participant has already taken this quiz.
  def taken_by?(participant)
    ResponseMap.where(reviewed_object_id: id, type: 'QuizResponseMap', reviewer_id: participant.id).any?
  end
end
