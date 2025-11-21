# frozen_string_literal: true

class CreateBookmarks < ActiveRecord::Migration[7.0]
  def change
    create_table :bookmarks do |t|
      t.text :url
      t.text :title
      t.text :description
      t.integer :user_id
      t.integer :topic_id

      t.timestamps
    end
  end
end
