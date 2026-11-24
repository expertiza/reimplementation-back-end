# frozen_string_literal: true

# quiz_question_choices was the one table still on latin1 (inherited from
# the old Expertiza schema). Every other table is utf8mb4, and the legacy
# data contains non-ASCII quiz text that latin1 would corrupt on import,
# so the canonical chain converts it to the standard utf8mb4 set (utf8mb4_general_ci - supported by both MySQL 8.x and MariaDB 10.x/11.x, unlike the MySQL-only utf8mb4_0900_ai_ci).
class ConvertQuizQuestionChoicesToUtf8mb4 < ActiveRecord::Migration[8.0]
  def up
    # Cache the legacy detection for the whole run: the convergence
    # (20261101000005) drops the marker tables, so re-evaluating
    # legacy_source? afterwards would flip to false on a legacy DB.
    @was_legacy = legacy_source?
    ActiveRecord.dump_schema_after_migration = false if @was_legacy
    return if @was_legacy

    execute "ALTER TABLE quiz_question_choices CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
  end

  def down
    execute "ALTER TABLE quiz_question_choices CONVERT TO CHARACTER SET latin1"
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
