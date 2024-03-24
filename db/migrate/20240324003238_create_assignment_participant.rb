class CreateAssignmentParticipant < ActiveRecord::Migration[7.0]
  def change
    create_table :assignment_participants do |t|

      t.timestamps
    end
  end
end
