class AddReviewingIsDoneByTeamsToResponseMaps < ActiveRecord::Migration[7.1]
  def up
    add_column :response_maps, :reviewing_is_done_by_teams, :boolean, default: false, null: false unless column_exists?(:response_maps, :reviewing_is_done_by_teams)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
