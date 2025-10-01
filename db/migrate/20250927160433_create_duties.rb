class CreateDuties < ActiveRecord::Migration[8.0]
  def change
    create_table :duties do |t|
      t.string :name
      t.integer :max_members_for_duty
      t.integer :assignment_id

      t.timestamps
    end

    add_index :duties, :assignment_id, name: "index_duties_on_assignment_id"
  end
end
