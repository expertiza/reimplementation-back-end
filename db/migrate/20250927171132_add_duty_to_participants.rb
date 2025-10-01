class AddDutyToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_reference :participants, :duty, foreign_key: true, index: true
  end
end
