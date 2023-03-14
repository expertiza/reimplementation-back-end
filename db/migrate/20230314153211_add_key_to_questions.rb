class AddKeyToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_reference :questions, :questionnaire, null: false, foreign_key: true, index: {name: 'fk_question_questionnaires'}
  end
end
