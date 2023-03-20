class CreateAnswers < ActiveRecord::Migration[7.0]
  def change
    create_table :answers do |t|
      t.column :instance_id, :integer, null: false
      t.column :question_id, :integer, null: false
      t.column :questionnaire_type_id, :integer, null: false
      t.column :answer, :integer, null: true
      t.column :comments, :text

      t.timestamps
    end
    add_index 'answers', ['question_id'], name: 'fk_score_questions'

=begin
    execute "alter table answers
               add constraint fk_score_questions
               foreign key (question_id) references questions(id)"

    add_index 'answers', ['questionnaire_type_id'], name: 'fk_score_questionnaire_types'

    execute ' ALTER TABLE `questionnaire_types`  ENGINE = innodb'

    execute "alter table answers
               add constraint fk_score_questionnaire_types
               foreign key (questionnaire_type_id) references questionnaire_types(id)"
=end
  end
end
