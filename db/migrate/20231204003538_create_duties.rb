class CreateDuties < ActiveRecord::Migration[7.0]
  def change
    create_table :duties do |t|
      t.string :name

      t.timestamps
    end
  end
end
