class RenameNameColumnsInUsers < ActiveRecord::Migration[8.0]
  def change
    # Order matters: free up :name (the login) before :full_name takes it
    rename_column :users, :name, :username
    rename_column :users, :full_name, :name
  end
end
