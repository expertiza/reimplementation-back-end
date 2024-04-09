# Migration to create the question_advices table in the database
class CreateQuestionAdvices < ActiveRecord::Migration[7.0]
  # Method to define changes to be made to the database
  def change
    # Creates a new table named question_advices
    create_table :question_advices do |t|
      # Adds a reference to the questions table. Each question_advice is associated with a question.
      # The `null: false` constraint ensures that every question_advice must have an associated question.
      t.references :question, null: false, foreign_key: true
      
      # Adds an integer column named score to store the score associated with the advice.
      t.integer :score
      
      # Adds a text column named advice to store the advice text.
      t.text :advice

      # Adds created_at and updated_at columns automatically to track when question advices are created and updated.
      t.timestamps
    end
  end
end
