class AddAssignmentToQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    # Adds the foreign key to link the questionnaires to the assignment id
    add_reference :questionnaires, :assignment, null: false, foreign_key: true
  end
end
