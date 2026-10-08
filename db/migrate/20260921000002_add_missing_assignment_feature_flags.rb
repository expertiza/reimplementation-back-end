class AddMissingAssignmentFeatureFlags < ActiveRecord::Migration[7.1]
  def change
    add_column :assignments, :vary_by_topic,              :boolean, default: false
    add_column :assignments, :vary_by_role,               :boolean, default: false
    add_column :assignments, :has_mentors,                :boolean, default: false
    add_column :assignments, :auto_assign_mentor,         :boolean, default: false
    add_column :assignments, :team_members_have_duties,   :boolean, default: false
    add_column :assignments, :bidding_for_reviews_enabled, :boolean, default: false
    add_column :assignments, :topics_assigned_by_bidding, :boolean, default: false
    add_column :assignments, :reviewing_is_done_by_teams, :boolean, default: false
  end
end
