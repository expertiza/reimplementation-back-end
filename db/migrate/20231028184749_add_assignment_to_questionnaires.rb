class AddAssignmentToQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    add_reference :questionnaires, :assignment, null: false, foreign_key: true
  end
end
