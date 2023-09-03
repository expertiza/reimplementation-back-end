class CreateQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table :questionnaires do |t|
      t.integer "max_question_score"

      t.timestamps
    end
  end
end
