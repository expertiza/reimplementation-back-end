class CreateBids < ActiveRecord::Migration[8.0]
  def change
    create_table :bids do |t|
      t.integer :topic_id
      t.integer :team_id
      t.integer :priority

      t.timestamps
    end
    
    add_index :bids, :team_id
    add_index :bids, :topic_id
  end
end
