class AddAnswerTextToAnswers < ActiveRecord::Migration[7.0]
  def change
    unless column_exists? :answers, :answer_text
      add_column :answers, :answer_text, :text
    end
  end
end
