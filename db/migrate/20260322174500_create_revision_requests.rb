class CreateRevisionRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :revision_requests do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :assignment, null: false, foreign_key: true
      t.string :status, null: false, default: 'PENDING'
      t.text :comments, null: false
      t.text :response_comment

      t.timestamps
    end

    add_index :revision_requests, %i[participant_id team_id status], name: 'index_revision_requests_on_participant_team_status'
  end
end
