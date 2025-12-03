class RenameItemIdInQuestionTables < ActiveRecord::Migration[8.0]
  def change
    rename_column :answers, :question_id, :item_id
    rename_column :question_advices, :question_id, :item_id
    rename_column :quiz_question_choices, :question_id, :item_id
  end
end
