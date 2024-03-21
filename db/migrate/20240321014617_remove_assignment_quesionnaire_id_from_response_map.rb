class RemoveAssignmentQuesionnaireIdFromResponseMap < ActiveRecord::Migration[7.0]
  def change
    remove_column :response_maps, :assignment_questionnaire_id
  end
end
