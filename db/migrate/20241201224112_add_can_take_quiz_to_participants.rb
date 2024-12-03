class AddCanTakeQuizToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :can_take_quiz, :boolean
  end
end
