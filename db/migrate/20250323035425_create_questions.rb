class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.text :txt
      t.integer :weight
      t.decimal :seq
      t.string :question_type
      t.string :size
      t.string :alternatives
      t.boolean :break_before
      t.string :max_label
      t.string :min_label

      t.timestamps
    end
    add_reference :questions, :questionnaire, null: false, foreign_key: true
    add_index :questions, :questionnaire_id, name: :fk_question_questionnaires

  end
end

