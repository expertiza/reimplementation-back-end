# frozen_string_literal: true

class CreateJoinTeamRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :join_team_requests do |t|

      t.timestamps
    end
  end
end
