class AddColumnTypeResponseMaps < ActiveRecord::Migration[7.0]
  def change
    add_column :response_maps, :type, :string, default: "", null: false
    add_column :response_maps, :calibrate_to, :boolean, default: false
    add_column :response_maps, :team_reviewing_enabled, :boolean, default: false
    add_column :responses, :version_num, :integer
    add_column :responses, :round, :integer
    add_column :responses, :visibility, :string, default: 'private'
  end
end
