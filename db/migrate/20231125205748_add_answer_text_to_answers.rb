class AddAnswerTextToAnswers < ActiveRecord::Migration[7.0]
  def change
    add_column :answers, :answer_text, :text
  end
end
