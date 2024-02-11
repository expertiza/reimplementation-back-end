class CreateAnswers < ActiveRecord::Migration[7.0]
  def change
    create_table :answers do |t|
      t.integer "question_id", default: 0, null: false
      t.integer "response_id"
      t.integer "answer"
      t.text "comments"
      t.index ["question_id"], name: "fk_score_questions"
      t.index ["response_id"], name: "fk_score_response"

      t.timestamps
    end
  end
end
