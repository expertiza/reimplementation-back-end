class AddCalibrateToToResponseMaps < ActiveRecord::Migration[7.1]
  def change
    add_column :response_maps, :calibrate_to, :boolean, default: false, null: false
  end
end
