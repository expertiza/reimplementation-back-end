class CreateAssignmentsDuties < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments_duties do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :duty, null: false, foreign_key: true

      t.timestamps
    end
  end
end
