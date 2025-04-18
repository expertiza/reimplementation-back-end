class RenameTagPromptAssignmentsToTagPromptDeployments < ActiveRecord::Migration[8.0]
  def change
    rename_table :tag_prompt_assignments, :tag_prompt_deployments
  end
end
