class AddCalibrateToToResponseMaps < ActiveRecord::Migration[7.1]
  def change
    add_column :response_maps, :for_calibration, :boolean, default: false, null: false
  end
end
