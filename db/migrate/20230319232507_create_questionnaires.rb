class CreateQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table :questionnaires do |t|
      t.integer "assignment_id"
      t.integer "max_question_score"
      t.index ["assignment_id"], name: "fk_questionnaires_assignment"
    end
  end
end
