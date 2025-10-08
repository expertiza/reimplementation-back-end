class AddInstructorIdAndPrivateToDuties < ActiveRecord::Migration[8.0]
  def change
    add_column :duties, :instructor_id, :bigint
    add_column :duties, :private, :boolean, default: false
    add_foreign_key :duties, :users, column: :instructor_id
    add_index :duties, :instructor_id
  end
end
