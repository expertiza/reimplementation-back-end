class CreateResponseMaps < ActiveRecord::Migration[7.0]
  def change
    create_table :response_maps do |t|
      t.integer :reviewed_object_id
      t.integer :reviewer_id
      t.integer :reviewee_id
      t.string :type
      t.boolean :calibrate_to

      t.timestamps
    end
  end
end
