class Question < ApplicationRecord
    belongs_to :questionnaire # each question belongs to a specific questionnaire
    has_many :answers, dependent: :destroy
  
    def self.get_all_questions_with_comments_available(assignment_id)
      question_ids = []
      questionnaires = Assignment.find(assignment_id).questionnaires.select { |questionnaire| questionnaire.type == 'ReviewQuestionnaire' }
      questionnaires.each do |questionnaire|
        questions = questionnaire.questions.select { |question| question.is_a?(ScoredQuestion) || question.instance_of?(TextArea) }
        questions.each { |question| question_ids << question.id }
      end
      question_ids
    end
end
  