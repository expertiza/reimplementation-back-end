class CreateTagPromptAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :tag_prompt_assignments do |t|
      t.integer :tag_prompt_id, null: false
      t.integer :assignment_id, null: false
      t.integer :questionnaire_id, null: false
      t.string  :question_type, limit: 255
      t.integer :answer_length_threshold
  
      t.timestamps
    end
  
    add_index :tag_prompt_assignments, :tag_prompt_id
    add_index :tag_prompt_assignments, :assignment_id
    add_index :tag_prompt_assignments, :questionnaire_id
  end
end
