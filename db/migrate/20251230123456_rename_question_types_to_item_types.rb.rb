class RenameQuestionTypesToItemTypes < ActiveRecord::Migration[8.0]
  def change
    rename_table :question_types, :item_types
  end
end
