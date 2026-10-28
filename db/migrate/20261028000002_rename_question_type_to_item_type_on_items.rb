# frozen_string_literal: true

class RenameQuestionTypeToItemTypeOnItems < ActiveRecord::Migration[7.1]
  def change
    rename_column :items, :question_type, :item_type
  end
end
