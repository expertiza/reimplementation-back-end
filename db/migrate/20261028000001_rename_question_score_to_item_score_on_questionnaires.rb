# frozen_string_literal: true

class RenameQuestionScoreToItemScoreOnQuestionnaires < ActiveRecord::Migration[7.1]
  # Guarded so the migration is a no-op on databases that already carry the
  # new column names (and a re-run cannot duplicate the rename).
  def up
    rename_column :questionnaires, :min_question_score, :min_item_score if column_exists?(:questionnaires, :min_question_score) && !column_exists?(:questionnaires, :min_item_score)
    rename_column :questionnaires, :max_question_score, :max_item_score if column_exists?(:questionnaires, :max_question_score) && !column_exists?(:questionnaires, :max_item_score)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
