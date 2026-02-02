class RenameItemForeignKeyIndexInAnswers < ActiveRecord::Migration[8.0]
  def change
    remove_index :answers, name: "fk_score_questions"
    add_index :answers, :item_id, name: "fk_score_items"
  end
end
