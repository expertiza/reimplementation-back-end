class AddTeachingAssistantToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :teaching_assistant, :boolean
  end
end
