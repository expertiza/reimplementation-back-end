class CreateQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table :questionnaires do |t|
      t.string :name
      t.integer :instructor_id
      t.boolean :private
      t.integer :min_question_score
      t.integer :max_question_score
      t.string :questionnaire_type
      t.string :display_type
      t.text :instruction_loc

      t.timestamps
    end
  end
end
