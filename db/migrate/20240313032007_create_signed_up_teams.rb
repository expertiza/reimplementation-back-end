class CreateSignedUpTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :signed_up_teams do |t|
      t.integer "topic_id", default: 0, null: false
      t.integer "team_id", default: 0, null: false
      t.boolean "is_waitlisted", default: false, null: false
      t.integer "preference_priority_number"
      t.index ["topic_id"], name: "fk_signed_up_users_sign_up_topics"
    end
  end
end
