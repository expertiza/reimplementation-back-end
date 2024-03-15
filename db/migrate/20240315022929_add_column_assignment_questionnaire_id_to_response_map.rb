class AddColumnAssignmentQuestionnaireIdToResponseMap < ActiveRecord::Migration[7.0]
  def change
    add_column :response_maps, :assignment_questionnaire_id, :integer
  end
end
