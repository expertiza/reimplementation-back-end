# frozen_string_literal: true

class QuizQuestionnaire < Questionnaire
    attr_accessor :questionnaire
    after_initialize :post_initialization
    
    def post_initialization
      self.display_type = 'Quiz'
    end
  
    def symbol
      'quiz'.to_sym
    end

    def get_assessments_for(participant)
        participant.quizzes_taken
    end

    def taken_by_anyone?
        !ResponseMap.where(reviewed_object_id: id, type: 'QuizResponseMap').empty?
    end
    
    def taken_by?(participant)
        !ResponseMap.where(reviewed_object_id: id, type: 'QuizResponseMap', reviewer_id: participant.id).empty?
    end
end
