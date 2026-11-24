class RenameSignUpTopicToProjectTopicInSignedUpTeams < ActiveRecord::Migration[8.0]
  def up
    # Guard the column rename: if the source column is already gone the database
    # is already migrated (or a prior interrupted run renamed it), so skip. This
    # also makes a re-run after a partially-applied migration safe.
    if column_exists?(:signed_up_teams, :sign_up_topic_id)
      rename_column :signed_up_teams, :sign_up_topic_id, :project_topic_id
    end

    # Rails >= 7.1 renames a conventionally-named index as part of
    # `rename_column`, so by the time we get here the index usually already
    # carries the new name and an unconditional `rename_index` of the old name
    # raises "Key ... doesn't exist" (which is what broke from-scratch builds).
    # Rename it explicitly only when the old name is still present.
    if index_exists?(:signed_up_teams, :index_signed_up_teams_on_sign_up_topic_id)
      rename_index :signed_up_teams,
                   :index_signed_up_teams_on_sign_up_topic_id,
                   :index_signed_up_teams_on_project_topic_id
    end
  end

  def down
    if index_exists?(:signed_up_teams, :index_signed_up_teams_on_project_topic_id)
      rename_index :signed_up_teams,
                   :index_signed_up_teams_on_project_topic_id,
                   :index_signed_up_teams_on_sign_up_topic_id
    end
    if column_exists?(:signed_up_teams, :project_topic_id) && !column_exists?(:signed_up_teams, :sign_up_topic_id)
      rename_column :signed_up_teams, :project_topic_id, :sign_up_topic_id
    end
  end
end

