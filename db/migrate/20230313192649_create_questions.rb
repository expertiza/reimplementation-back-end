class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.column 'txt', :text # the question content
      t.column 'true_false', :boolean # is this a true/false question?
      t.column 'weight', :integer # the scoring weight
      t.column 'questionnaire_id', :integer # the questionnaire to which this question belongs
      t.column 'seq', :float, default: nil
      t.column 'type', :string
      t.column 'size', :string
      t.column 'alternatives', :string
      t.column 'break_before', :boolean, default: true
      t.column 'max_label', :string, default: ''
      t.column 'min_label', :string, default: ''

      t.timestamps
    end

    add_index 'questions', ['questionnaire_id'], name: 'fk_question_questionnaires'

  end
end
