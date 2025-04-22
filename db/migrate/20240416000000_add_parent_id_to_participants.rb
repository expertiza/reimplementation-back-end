class AddParentIdToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :parent_id, :integer
    add_index :participants, :parent_id
  end
end 