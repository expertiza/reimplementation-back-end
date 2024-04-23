class AddPermissionGrantedToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :permission_granted, :boolean
  end
end
