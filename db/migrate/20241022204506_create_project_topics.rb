class CreateProjectTopics < ActiveRecord::Migration[7.0]
  def change
    create_table :project_topics do |t|
      t.text :topic_title
      t.integer :assignment_id, default: 0, null: false
      t.integer :max_signups, default: 0, null: false
      t.text :category
      t.string :topic_code, limit: 10
      t.text :description
      t.string :link

      t.timestamps
    end
  end
end
