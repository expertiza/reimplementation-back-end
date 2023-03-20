class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.integer "questionnaire_id"
      t.integer "weight"
      t.index ["questionnaire_id"], name: "fk_question_questionnaires"
    end
  end
end
