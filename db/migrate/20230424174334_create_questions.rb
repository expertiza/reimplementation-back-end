class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.integer "weight"
      t.integer "questionnaire_id"
      t.index ["questionnaire_id"], name: "fk_question_questionnaires"

      t.timestamps
    end
  end
end
