class RenameQuestionIdToItemIdInQuizQuestionChoices < ActiveRecord::Migration[7.0]
  def change
    rename_column :quiz_question_choices, :question_id, :item_id

    # if you have an index on question_id, also rename it:
    if index_name_exists?(:quiz_question_choices, 'index_quiz_question_choices_on_question_id')
      rename_index :quiz_question_choices,
                   'index_quiz_question_choices_on_question_id',
                   'index_quiz_question_choices_on_item_id'
    end
  end
end
