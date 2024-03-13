class AddColumnsToParticipant < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :can_submit, :boolean, default: true
    add_column :participants, :can_review, :boolean, default: true
    add_column :participants, :parent_id, :integer
    add_column :participants, :submitted_at, :datetime
    add_column :participants, :permission_granted, :boolean
    add_column :participants, :duty, :string
    add_column :participants, :duty_id, :integer
    add_column :participants, :can_mentor, :boolean
  end
end
