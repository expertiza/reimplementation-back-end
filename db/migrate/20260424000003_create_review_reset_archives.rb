# frozen_string_literal: true

class CreateReviewResetArchives < ActiveRecord::Migration[8.0]
  def change
    create_table :review_reset_archives do |t|
      t.integer :response_id, null: false
      t.integer :map_id, null: false
      t.integer :assignment_id, null: false
      t.integer :questionnaire_id, null: false
      t.bigint :project_topic_id
      t.integer :round
      t.integer :reviewer_id
      t.integer :reviewee_id
      t.string :reset_reason, null: false
      t.json :snapshot_data, null: false

      t.timestamps
    end

    add_index :review_reset_archives, :response_id
    add_index :review_reset_archives, :assignment_id
    add_index :review_reset_archives, :questionnaire_id
    add_index :review_reset_archives, :project_topic_id
    add_index :review_reset_archives, :reset_reason
  end
end
