class AddHasTopicsToAssignment < ActiveRecord::Migration[7.0]
  def change
    add_column :assignments, :has_topics, :boolean, default: false
  end
end
