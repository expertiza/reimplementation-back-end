class AddCorrectAnswerToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :correct_answer, :string
  end
end
