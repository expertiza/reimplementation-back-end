class CreateAssignmentParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_participants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.string :handle

      t.timestamps
    end
  end
end
