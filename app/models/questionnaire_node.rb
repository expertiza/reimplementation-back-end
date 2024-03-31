class QuestionnaireNode < Node
  belongs_to :questionnaire, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false
  belongs_to :node_object, class_name: 'Questionnaire', foreign_key: 'node_object_id', inverse_of: false

  def self.table
    'questionnaires'
  end
end
