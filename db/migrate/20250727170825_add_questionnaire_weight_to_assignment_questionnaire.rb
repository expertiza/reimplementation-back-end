class AddQuestionnaireWeightToAssignmentQuestionnaire < ActiveRecord::Migration[8.0]
  def change
    add_column :assignment_questionnaires, :questionnaire_weight, :integer
  end
end
