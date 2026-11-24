class AddCalibrateToToResponseMaps < ActiveRecord::Migration[7.1]
  # The 20260320011304 legacy bridge migration adds :for_calibration on a
  # migrated database (and on a from-scratch chain), so guard against a
  # duplicate-column error on the merged chain.
  def up
    add_column :response_maps, :for_calibration, :boolean, default: false, null: false unless column_exists?(:response_maps, :for_calibration)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
