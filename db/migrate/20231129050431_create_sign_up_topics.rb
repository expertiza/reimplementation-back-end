# frozen_string_literal: true

class CreateSignUpTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :project_topics do |t|
      t.text :topic_name, null: false
      t.references :assignment, null: false, foreign_key: true
      t.integer :max_choosers, default: 0, null: false
      t.text :category
      t.string :topic_identifier, limit: 10
      t.integer :micropayment, default: 0
      t.integer :private_to
      t.text :description
      t.string :link
      t.index ["assignment_id"], name: "fk_sign_up_categories_sign_up_topics"
      t.timestamps
    end
  end
end
