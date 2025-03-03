class CreateTopics < ActiveRecord::Migration[8.0]
  def change
    create_table :topics do |t|
      t.integer :max_accepted_proposals

      t.timestamps
    end
  end
end
