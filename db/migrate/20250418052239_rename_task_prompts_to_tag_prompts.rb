class RenameTaskPromptsToTagPrompts < ActiveRecord::Migration[8.0]
  def change
    rename_table :task_prompts, :tag_prompts
  end
end
