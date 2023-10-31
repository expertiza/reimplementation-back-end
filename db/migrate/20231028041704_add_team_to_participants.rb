class AddTeamToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_reference :participants, :team, null: false, foreign_key: true
  end
end
