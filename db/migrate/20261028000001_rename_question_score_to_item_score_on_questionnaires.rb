# frozen_string_literal: true

class RenameQuestionScoreToItemScoreOnQuestionnaires < ActiveRecord::Migration[7.1]
  def change
    rename_column :questionnaires, :min_question_score, :min_item_score
    rename_column :questionnaires, :max_question_score, :max_item_score
  end
end
