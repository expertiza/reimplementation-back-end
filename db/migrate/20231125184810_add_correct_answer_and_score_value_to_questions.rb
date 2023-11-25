class AddCorrectAnswerAndScoreValueToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :correct_answer, :string
    add_column :questions, :score_value, :integer
  end
end
