class CreateAssignmentQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table :assignment_questionnaires do |t|
      t.integer "assignment_id"
      t.integer "questionnaire_id"
      t.integer "notification_limit", default: 15, null: false
      t.index ["assignment_id"], name: "fk_aq_assignments_id"
      t.index ["questionnaire_id"], name: "fk_aq_questionnaire_id"

      t.timestamps
    end
  end
end
