class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.integer :max_team_size, null: false, default: 5
      t.references :user, foreign_key: true
      t.references :course, foreign_key: true
      t.references :assignment, foreign_key: true
      t.references :mentor, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :teams, :type

    create_table :team_members do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: 'member'

      t.timestamps

      t.index [:team_id, :user_id], unique: true
    end

    create_table :team_join_requests do |t|
      t.references :team, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'

      t.timestamps

      t.index [:team_id, :user_id], unique: true
    end
  end
end 