class CreateQuizQuestionChoices < ActiveRecord::Migration[7.0]
  def change
    create_table :quiz_question_choices do |t|
      t.column 'question_id', :integer # the question to which this advice belongs
      t.column 'txt', :text # the choice to be given to the user
      t.column 'iscorrect', :boolean, default: false # the correctness of this choice to be given to the user

      t.timestamps
    end
  end
end
