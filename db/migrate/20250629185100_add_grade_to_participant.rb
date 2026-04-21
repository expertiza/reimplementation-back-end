class AddGradeToParticipant < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :grade, :float unless column_exists?(:participants, :grade)
  end
end
