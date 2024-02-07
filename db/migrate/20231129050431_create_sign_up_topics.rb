class CreateSignUpTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :sign_up_topics do |t|
      t.text :topic_name
      t.references :assignment, null: false, foreign_key: true
      t.integer :max_choosers
      t.text :category
      t.string :topic_identifier
      t.integer :micropayment
      t.integer :private_to
      t.text :description
      t.string :link

      t.timestamps
    end
  end
end
