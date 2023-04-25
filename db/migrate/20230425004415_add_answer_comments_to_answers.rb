class AddAnswerCommentsToAnswers < ActiveRecord::Migration[7.0]
  def change
    add_column :answers, :answer, :integer
    add_column :answers, :comments, :text
  end
end
