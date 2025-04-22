class CreateTaskPrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :task_prompts do |t|
      t.string :prompt, limit: 255
      t.string :desc, limit: 255
      t.string :control_type, limit: 255

      t.timestamps
    end
  end
end
