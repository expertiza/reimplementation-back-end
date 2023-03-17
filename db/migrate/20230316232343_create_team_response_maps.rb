class CreateTeamResponseMaps < ActiveRecord::Migration[7.0]
  def change
    create_table :team_response_maps do |t|
      t.boolean :team_reviewing_enabled

      t.timestamps
    end
  end
end
