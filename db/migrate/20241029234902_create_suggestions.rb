class CreateSuggestions < ActiveRecord::Migration[7.0]
  def change
    create_table :suggestions do |t|
      t.string :title
      t.text :description
      t.string :status
      t.boolean :auto_signup
      t.references :assignment, null: false, foreign_key: true
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
