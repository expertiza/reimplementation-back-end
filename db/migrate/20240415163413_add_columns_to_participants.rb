class AddColumnsToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :topic, :string
    add_column :participants, :current_stage, :string
    add_column :participants, :stage_deadline, :datetime
  end
end
