class CreateDuties < ActiveRecord::Migration[8.0]
  def change
    create_table :duties do |t|
      t.string :name

      t.timestamps
    end
  end
end
