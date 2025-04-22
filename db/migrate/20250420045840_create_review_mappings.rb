class CreateReviewMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :review_mappings do |t|
      t.references :reviewer, foreign_key: { to_table: :users }
      t.references :reviewee, foreign_key: { to_table: :users }
      t.references :assignment, foreign_key: true
      t.string :review_type
      t.string :status

      t.timestamps
    end
  end
end
