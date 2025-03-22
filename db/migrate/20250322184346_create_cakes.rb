class CreateCakes < ActiveRecord::Migration[8.0]
  def change
    create_table :cakes do |t|
      t.timestamps
    end
  end
end
