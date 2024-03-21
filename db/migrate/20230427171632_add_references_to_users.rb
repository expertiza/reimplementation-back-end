class AddReferencesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :institution, foreign_key: true
    add_reference :users, :role, foreign_key: true, null: false
    add_reference :users, :parent, foreign_key: { to_table: :users }, optional: true
  end
end
