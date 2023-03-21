class CreateSignUpTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :sign_up_topics do |t|
      t.integer :topic_identifier
      t.string :category
      t.string :topic_name
      t.integer :max_choosers
      t.references :assignment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
