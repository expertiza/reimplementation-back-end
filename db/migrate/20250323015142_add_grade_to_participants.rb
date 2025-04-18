class AddGradeToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :grade, :float
  end
end
