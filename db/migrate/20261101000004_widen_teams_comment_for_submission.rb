# frozen_string_literal: true

# teams.comment_for_submission was a MEDIUMTEXT free-text column in legacy
# Expertiza, but the reimplementation chain defined it as a 255-char string.
# Production data contains 468 comments longer than 255 characters (max
# 1338), and GradesController writes unbounded user input here, so the
# canonical chain must also hold TEXT. This keeps both database shapes
# identical after the legacy convergence (20261101000004).
class WidenTeamsCommentForSubmission < ActiveRecord::Migration[8.0]
  def up
    # Cache the legacy detection for the whole run: the convergence
    # (20261101000005) drops the marker tables, so re-evaluating
    # legacy_source? afterwards would flip to false on a legacy DB.
    @was_legacy = legacy_source?
    ActiveRecord.dump_schema_after_migration = false if @was_legacy
    return if @was_legacy

    change_column :teams, :comment_for_submission, :text
  end

  def down
    change_column :teams, :comment_for_submission, :string
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
