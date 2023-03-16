class CreateQuestionnaires < ActiveRecord::Migration[7.0]
  def change
    create_table :questionnaires do |t|
      t.column 'name', :string, limit: 64 # the name of the questionnaire
      t.column 'instructor_id', :integer, default: 0, null: false # the id of the instructor (as user) who created the questionnaire
      t.column 'private', :boolean, default: false, null: false # is the questionnaire private?
      t.column 'min_question_score', :integer, default: 0, null: false # the lowest possible score on a question
      t.column 'max_question_score', :integer # the greatest possible score on a question
      t.column 'default_num_choices', :integer # default number of scoring increments
      t.column 'type_id', :integer, default: 1, null: false # Questionnaire Type join

      t.timestamps
    end
    add_index 'questionnaires', ['type_id'], name: 'fk_questionnaire_type'

  end
end
