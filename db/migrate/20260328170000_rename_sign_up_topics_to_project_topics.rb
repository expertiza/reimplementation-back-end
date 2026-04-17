# frozen_string_literal: true

class RenameSignUpTopicsToProjectTopics < ActiveRecord::Migration[8.0]
  def up
    return if table_exists?(:project_topics)
    return unless table_exists?(:sign_up_topics)

    if foreign_key_exists?(:signed_up_teams, :sign_up_topics)
      remove_foreign_key :signed_up_teams, :sign_up_topics
    end

    rename_table :sign_up_topics, :project_topics

    if index_name_exists?(:project_topics, "fk_sign_up_categories_sign_up_topics") &&
       !index_name_exists?(:project_topics, "index_project_topics_on_assignment_id")
      rename_index :project_topics,
                   "fk_sign_up_categories_sign_up_topics",
                   "index_project_topics_on_assignment_id"
    end

    if column_exists?(:signed_up_teams, :project_topic_id) &&
       !foreign_key_exists?(:signed_up_teams, :project_topics)
      add_foreign_key :signed_up_teams, :project_topics
    end
  end

  def down
    return if table_exists?(:sign_up_topics)
    return unless table_exists?(:project_topics)

    remove_foreign_key :signed_up_teams, :project_topics if foreign_key_exists?(:signed_up_teams, :project_topics)

    if index_name_exists?(:project_topics, "index_project_topics_on_assignment_id") &&
       !index_name_exists?(:project_topics, "fk_sign_up_categories_sign_up_topics")
      rename_index :project_topics,
                   "index_project_topics_on_assignment_id",
                   "fk_sign_up_categories_sign_up_topics"
    end

    rename_table :project_topics, :sign_up_topics

    if column_exists?(:signed_up_teams, :project_topic_id) &&
       !foreign_key_exists?(:signed_up_teams, :sign_up_topics)
      add_foreign_key :signed_up_teams, :sign_up_topics, column: :project_topic_id
    end
  end
end
