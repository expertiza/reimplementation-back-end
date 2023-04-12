class ChangeForiegnKeyForWaitlists < ActiveRecord::Migration[7.0]
  def change
    rename_column :waitlists, :sign_up_topic_id, :signup_topic_id
  end
end
