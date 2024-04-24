class AddFieldsToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :submitted_hyperlinks, :text
    add_column :teams, :directory_num, :integer

    add_reference :teams, :assignment, foreign_key: true
  end
end
