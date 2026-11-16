class AddReviewingIsDoneByTeamsToResponseMaps < ActiveRecord::Migration[7.1]
  def change
    add_column :response_maps, :reviewing_is_done_by_teams, :boolean, default: false, null: false
  end
end
