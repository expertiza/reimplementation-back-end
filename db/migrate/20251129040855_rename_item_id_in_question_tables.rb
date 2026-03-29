class RenameItemIdInQuestionTables < ActiveRecord::Migration[8.0]
  def change
    rename_column_if_needed :answers
    rename_column_if_needed :question_advices
    rename_column_if_needed :quiz_question_choices
  end

  private

  def rename_column_if_needed(table_name)
    return unless column_exists?(table_name, :question_id)
    return if column_exists?(table_name, :item_id)

    rename_column table_name, :question_id, :item_id
  end
end