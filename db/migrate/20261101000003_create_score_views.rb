# frozen_string_literal: true

# The ScoreView model (weighted quiz scoring) reads the `score_views`
# MySQL view. A database built from the clean 2023-2026 chain never had
# this view (it existed only in legacy Expertiza), so quiz scoring was
# broken there. The legacy bridge already recreates it against the
# renamed tables (20261023000000); this migration creates the same view
# on the clean chain so both database shapes behave identically.
#
# No DEFINER clause on purpose: a hardcoded legacy definer account breaks
# in environments where that account/privileges do not exist; without it
# MySQL/MariaDB uses the creating user as definer, which is portable.
class CreateScoreViews < ActiveRecord::Migration[8.0]
  def up
    # Cache the legacy detection for the whole run: the convergence
    # (20261101000005) drops the marker tables, so re-evaluating
    # legacy_source? afterwards would flip to false on a legacy DB.
    @was_legacy = legacy_source?
    ActiveRecord.dump_schema_after_migration = false if @was_legacy
    return if @was_legacy

    return unless table_exists?(:items) && table_exists?(:questionnaires) && table_exists?(:answers)
    return unless column_exists?(:answers, :item_id)

    execute "DROP VIEW IF EXISTS score_views"
    execute <<~SQL
      CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `score_views` AS
      SELECT ques.`weight` AS `question_weight`,
             ques.`type` AS `type`,
             q1.`id` AS `q1_id`,
             q1.`name` AS `q1_name`,
             q1.`instructor_id` AS `q1_instructor_id`,
             q1.`private` AS `q1_private`,
             q1.`min_question_score` AS `q1_min_question_score`,
             q1.`max_question_score` AS `q1_max_question_score`,
             q1.`created_at` AS `q1_created_at`,
             q1.`updated_at` AS `q1_updated_at`,
             q1.`type` AS `q1_type`,
             q1.`display_type` AS `q1_display_type`,
             ques.`id` AS `ques_id`,
             ques.`questionnaire_id` AS `ques_questionnaire_id`,
             s.`id` AS `s_id`,
             s.`item_id` AS `s_question_id`,
             s.`answer` AS `s_score`,
             s.`comments` AS `s_comments`,
             s.`response_id` AS `s_response_id`
      FROM ((`items` `ques` LEFT JOIN `questionnaires` `q1` ON ((`ques`.`questionnaire_id` = `q1`.`id`)))
            LEFT JOIN `answers` `s` ON ((`ques`.`id` = `s`.`item_id`)))
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS score_views"
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
