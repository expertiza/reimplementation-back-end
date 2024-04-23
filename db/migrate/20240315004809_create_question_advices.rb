class CreateQuestionAdvices < ActiveRecord::Migration[7.0]
  def change
    create_table :question_advices do |t|
      t.references :question, null: false, foreign_key: true
      t.integer :score
      t.text :advice

      t.timestamps
    end
  end
end
