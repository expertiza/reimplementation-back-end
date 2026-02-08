class RenameStatusToReplyStatusInInJoinTeamRequests < ActiveRecord::Migration[8.0]
  def change
    rename_column :join_team_requests, :status, :reply_status
  end
end
