class ChangeQuestionToItemInAnswers < ActiveRecord::Migration[8.0]
  def change
    rename_column :answers, :question_id, :item_id
  end
end
