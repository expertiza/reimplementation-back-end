class AddCorrectAnswerToQuestions < ActiveRecord::Migration[7.0]
  def change
    unless column_exists? :questions, :correct_answer
      add_column :questions, :correct_answer, :string
    end
  end
end
