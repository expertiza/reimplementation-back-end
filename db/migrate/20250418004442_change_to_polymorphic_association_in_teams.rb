class ChangeToPolymorphicAssociationInTeams < ActiveRecord::Migration[8.0]
  def change
    if foreign_key_exists?(:teams, :assignments)
      remove_reference :teams, :assignment, foreign_key: true
    elsif column_exists?(:teams, :assignment_id)
      remove_column :teams, :assignment_id
    end

    add_column :teams, :parent_id, :integer, null: false unless column_exists?(:teams, :parent_id)
    add_column :teams, :type, :string unless column_exists?(:teams, :type)
    add_index :teams, :type unless index_exists?(:teams, :type)
  end
end
