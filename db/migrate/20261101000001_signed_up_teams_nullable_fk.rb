# frozen_string_literal: true

# Legacy Expertiza used project_topic_id = 0 / team_id = 0 as "no topic /
# no team" sentinels (the columns were NOT NULL DEFAULT 0). The new format
# models express "none" with NULL, and the legacy 0 rows must be NULLed
# during the legacy convergence (20261101000004), which requires the
# columns to be nullable. SignedUpTeam keeps explicit presence validations
# so the app behavior (friendly error, never a silent 0/NULL) is identical
# on both database shapes.
class SignedUpTeamsNullableFk < ActiveRecord::Migration[8.0]
  def up
    # Cache the legacy detection for the whole run: the convergence
    # (20261101000005) drops the marker tables, so re-evaluating
    # legacy_source? afterwards would flip to false on a legacy DB.
    @was_legacy = legacy_source?
    ActiveRecord.dump_schema_after_migration = false if @was_legacy
    return if @was_legacy

    change_column :signed_up_teams, :project_topic_id, :bigint, null: true
    change_column :signed_up_teams, :team_id, :bigint, null: true
  end

  def down
    change_column :signed_up_teams, :project_topic_id, :bigint, null: false
    change_column :signed_up_teams, :team_id, :bigint, null: false
  end

  # A legacy Expertiza DB still has tables the canonical chain never creates;
  # the canonical chain has none of them.
  def legacy_source?
    %w[sessions goldberg_roles goldberg_users versions
       review_strategies reviews automated_metareviews
       assignments_questionnaires].any? { |t| table_exists?(t) }
  end

  # `rake db:migrate` dumps db/schema.rb from whatever database it ran on
  # (ActiveRecord.dump_schema_after_migration, suppressed above on a legacy
  # source). Doing so on a legacy source would clobber the canonical
  # schema.rb with a legacy-shaped dump, so only the canonical chain dumps it.
  # @was_legacy (cached in up) is used because the convergence drops the
  # marker tables, so re-evaluating would flip mid-run.
  def change_schema!
    super unless @was_legacy
  end
end
