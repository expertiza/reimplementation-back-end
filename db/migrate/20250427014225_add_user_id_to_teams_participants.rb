# frozen_string_literal: true

class AddUserIdToTeamsParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :teams_participants, :user_id, :integer

    # 2) add an index on user_id
    add_index  :teams_participants, :user_id


    # 4) enforce NOT NULL to match the old schema
    change_column_null :teams_participants, :user_id, false
  end
end
