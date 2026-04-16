# frozen_string_literal: true

class AddForCalibrationToResponseMaps < ActiveRecord::Migration[8.0]
  def change
    add_column :response_maps, :for_calibration, :boolean, default: false, null: false
  end
end
