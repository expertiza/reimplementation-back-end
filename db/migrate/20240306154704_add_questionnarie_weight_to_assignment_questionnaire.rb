class AddQuestionnarieWeightToAssignmentQuestionnaire < ActiveRecord::Migration[7.0]
  def self.up
    add_column 'assignment_questionnaires', 'questionnaire_weight', :integer, default: 0, null: false
  end
  def self.down
    remove_column 'assignment_questionnaires', 'questionnaire_weight'
  end
end
