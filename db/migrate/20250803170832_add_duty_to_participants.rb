class AddDutyToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_reference :participants, :duty, null: true, foreign_key: true
  end
end
