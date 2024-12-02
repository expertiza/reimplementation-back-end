class AddDesignationToParticipant < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :designation, :string
  end
end
