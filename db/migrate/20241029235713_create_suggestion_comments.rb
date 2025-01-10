class CreateSuggestionComments < ActiveRecord::Migration[7.0]
  def change
    create_table :suggestion_comments do |t|
      t.text :comment
      t.references :suggestion, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
