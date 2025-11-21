# frozen_string_literal: true

class AddFieldsToJoinTeamRequests < ActiveRecord::Migration[7.0]
  def change
    add_column :join_team_requests, :participant_id, :integer
    add_column :join_team_requests, :team_id, :integer
    add_column :join_team_requests, :comments, :text
    add_column :join_team_requests, :status, :string
  end
end
