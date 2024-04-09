# Define a migration for creating the quiz_question_choices table in the database
class CreateQuizQuestionChoices < ActiveRecord::Migration[7.0]
  # Method defining changes to be made to the database
  def change
    # Create a new table named quiz_question_choices
    create_table :quiz_question_choices, id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.integer :question_id  # Column for storing the associated question's ID
      t.text :txt  # Column for storing the text of the quiz question choice
      t.boolean :iscorrect, default: false  # Boolean column indicating whether the choice is correct, defaulting to false

      t.timestamps  # Adds created_at and updated_at columns automatically
    end
  end
end
