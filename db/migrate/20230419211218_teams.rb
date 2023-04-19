class Teams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :team_name
    end
  end
end
