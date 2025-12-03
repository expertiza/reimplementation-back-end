# db/migrate/20251202_add_for_calibration_to_response_maps.rb
class AddForCalibrationToResponseMaps < ActiveRecord::Migration[8.0]
  def up
    # 1. Add the column if it doesn't already exist
    unless column_exists?(:response_maps, :for_calibration)
      add_column :response_maps, :for_calibration, :boolean, default: false, null: false
    end

    # 2. Backfill only if the old column exists in this DB
    if column_exists?(:response_maps, :to_calibrate)
      execute <<~SQL.squish
        UPDATE response_maps
        SET for_calibration = COALESCE(to_calibrate, false)
      SQL
    end
  end

  def down
    # Safe rollback
    remove_column :response_maps, :for_calibration if column_exists?(:response_maps, :for_calibration)
  end
end

