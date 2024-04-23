class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire
  belongs_to :sign_up_topic, class_name: 'SignUpTopic', foreign_key: 'topic_id'
  
  def self.get_questions_by_assignment_id(assignment_id)
    AssignmentQuestionnaire.find_by(['assignment_id = ? and questionnaire_id IN (?)',
                                     Assignment.find(assignment_id).id, ReviewQuestionnaire.select('id')])
                           .questionnaire.questions.reject { |q| q.is_a?(QuestionnaireHeader) }
  end
end
