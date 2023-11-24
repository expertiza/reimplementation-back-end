class AddCorrectToAnswers < ActiveRecord::Migration[7.0]
  def change
    # Adds the boolean flag to the answer to indicate the correct answer
    add_column :answers, :correct, :boolean, default: false
  end

end
