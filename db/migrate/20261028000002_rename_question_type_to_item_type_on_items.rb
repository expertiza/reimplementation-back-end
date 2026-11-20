# frozen_string_literal: true

class RenameQuestionTypeToItemTypeOnItems < ActiveRecord::Migration[7.1]
  # A from-scratch chain has :question_type to rename. A legacy-migrated
  # database does not (the legacy `questions` table used the STI :type
  # column), so create :item_type there and backfill it from :type so the
  # questionnaire subtype feature behaves the same on both paths.
  def up
    if column_exists?(:items, :question_type) && !column_exists?(:items, :item_type)
      rename_column :items, :question_type, :item_type
    elsif !column_exists?(:items, :item_type)
      add_column :items, :item_type, :string
      execute "UPDATE items SET item_type = type WHERE type IS NOT NULL AND item_type IS NULL" if column_exists?(:items, :type)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
