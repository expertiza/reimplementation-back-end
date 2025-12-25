# frozen_string_literal: true

class CreateNodes < ActiveRecord::Migration[7.0]
  def change
    create_table :nodes do |t|
      t.integer :parent_id
      t.integer :node_object_id
      t.string :type

      t.timestamps
    end
  end
end
