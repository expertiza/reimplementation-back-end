class AddAllowBookmarksToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :allow_bookmarks, :boolean, default: false, null: false
  end
end
