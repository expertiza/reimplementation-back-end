class AddMissingAssignmentFeatureFlags < ActiveRecord::Migration[7.1]
  # A legacy-migrated database already carries some of these flags (e.g.
  # bidding_for_reviews_enabled, auto_assign_mentor) from the legacy schema
  # and the 2026 bridge migrations, so every add is guarded to keep the
  # merged chain idempotent on both database paths.
  def up
    add_column :assignments, :vary_by_topic,              :boolean, default: false unless column_exists?(:assignments, :vary_by_topic)
    add_column :assignments, :vary_by_role,               :boolean, default: false unless column_exists?(:assignments, :vary_by_role)
    add_column :assignments, :has_mentors,                :boolean, default: false unless column_exists?(:assignments, :has_mentors)
    add_column :assignments, :auto_assign_mentor,         :boolean, default: false unless column_exists?(:assignments, :auto_assign_mentor)
    add_column :assignments, :team_members_have_duties,   :boolean, default: false unless column_exists?(:assignments, :team_members_have_duties)
    add_column :assignments, :bidding_for_reviews_enabled, :boolean, default: false unless column_exists?(:assignments, :bidding_for_reviews_enabled)
    add_column :assignments, :topics_assigned_by_bidding, :boolean, default: false unless column_exists?(:assignments, :topics_assigned_by_bidding)
    add_column :assignments, :reviewing_is_done_by_teams, :boolean, default: false unless column_exists?(:assignments, :reviewing_is_done_by_teams)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
