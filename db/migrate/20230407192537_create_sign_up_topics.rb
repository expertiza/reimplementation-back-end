class CreateSignUpTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :sign_up_topics do |t|
      t.string :name
      t.integer :max_choosers
      t.string :category
      t.string :topic_identifier
      t.string :description
      t.string :link

      t.timestamps
    end
  end
end
