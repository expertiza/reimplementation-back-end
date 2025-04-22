class AddTeamReviewingEnabledToResponseMaps < ActiveRecord::Migration[8.0]
  def change
    add_column :response_maps, :team_reviewing_enabled, :boolean, default: false
  end
end
