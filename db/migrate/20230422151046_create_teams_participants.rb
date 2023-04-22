class CreateTeamsParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :teams_participants do |t|

      t.timestamps
    end
  end
end
