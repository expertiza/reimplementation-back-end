class AddCanMentorToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :can_mentor, :boolean
  end
end
