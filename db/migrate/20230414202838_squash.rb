class Squash < ActiveRecord::Migration[7.0]
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

    create_table :teams do |t|
      t.string :name

      t.timestamps
    end

    create_table :signed_up_teams do |t|
      t.integer :preference_priority_number

      t.timestamps
    end

    add_reference :sign_up_topics, :assignment, null: false, foreign_key: true

    add_reference :signed_up_teams, :sign_up_topic, null: false, foreign_key: true

    add_reference :signed_up_teams, :team, null: false, foreign_key: true

    rename_table :sign_up_topics, :signup_topics

    rename_column :signed_up_teams, :sign_up_topic_id, :signup_topic_id

    add_column :signed_up_teams, :is_waitlisted, :boolean, :default => false
  end
end
