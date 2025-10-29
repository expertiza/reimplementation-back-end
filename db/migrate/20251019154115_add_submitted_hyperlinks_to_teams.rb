class AddSubmittedHyperlinksToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :submitted_hyperlinks, :text
  end
end
