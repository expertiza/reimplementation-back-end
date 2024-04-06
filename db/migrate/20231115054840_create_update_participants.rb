class CreateUpdateParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :update_participants do |t|

      t.timestamps
    end
  end
end
