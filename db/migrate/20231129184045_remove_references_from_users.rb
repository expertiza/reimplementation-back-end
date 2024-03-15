class RemoveReferencesFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_reference :users, :parent, foreign_key: { to_table: :users }
  end
end
