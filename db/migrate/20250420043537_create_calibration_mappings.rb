class CreateCalibrationMappings < ActiveRecord::Migration[8.0]
  def change
    create_table :calibration_mappings do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
  end
end
