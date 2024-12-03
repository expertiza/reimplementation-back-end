class AddCanSubmitToParticipant < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :can_submit, :boolean, :default => true
  end
end