class AddMissingAssignmentFeatureFlags < ActiveRecord::Migration[7.1]
  def change
    add_column :assignments, :vary_by_topic,                        :boolean, default: false
    add_column :assignments, :vary_by_role,                         :boolean, default: false
    add_column :assignments, :has_mentors,                          :boolean, default: false
    add_column :assignments, :auto_assign_mentor,                   :boolean, default: false
    add_column :assignments, :duty_based_assignment,                :boolean, default: false
    add_column :assignments, :bidding_for_reviews_enabled,          :boolean, default: false
    add_column :assignments, :enable_bidding_for_topics,            :boolean, default: false
    add_column :assignments, :enable_authors_to_review_other_topics,:boolean, default: false
    add_column :assignments, :team_reviewing_enabled,               :boolean, default: false
  end
end
