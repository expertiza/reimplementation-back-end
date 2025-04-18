class ChangeParticipantsToPolymorphicParent < ActiveRecord::Migration[8.0]
  def change
    # Remove old columns
    remove_column :participants, :assignment_id, :integer
    remove_column :participants, :course_id, :integer

    # Add polymorphic columns explicitly
    add_column :participants, :parent_id, :integer, null: false
  end
end
