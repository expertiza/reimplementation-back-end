class AddHandleToParticipant < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :handle, :string
  end
end
