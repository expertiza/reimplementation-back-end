class AddDutyIdToParticipants < ActiveRecord::Migration[8.0]
  def change
     unless column_exists?(:participants, :duty_id)
      add_reference :participants, :duty, null: true, foreign_key: true
    end
  end
end
