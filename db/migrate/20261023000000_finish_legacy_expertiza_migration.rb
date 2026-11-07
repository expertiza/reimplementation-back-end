# frozen_string_literal: true

# Completes the translation of a legacy Expertiza database into the
# reimplementation schema. It runs last in the legacy-migration sequence
# (after the guarded 2026 bridge chain) and performs the remaining table
# renames, data alignments and view repairs that no earlier migration covers:
#
#   * questions        -> items            (20250216020117, skipped on legacy)
#   * sign_up_topics   -> project_topics   (no migration ever renamed it)
#   * question_advices -> question_advice  (idempotent; 20260320011304 also does it)
#   * bids             -> topic_bids       (idempotent; 20260320011304 also does it)
#   * users.fullname   -> users.name       (legacy display name; 20260320011304
#                                          already moved legacy `name` to `username`)
#   * items.question_type populated from legacy STI `type`
#   * legacy duties.assignment_id translated into the assignments_duties join
#     table plus duties.instructor_id
#   * teams_users recreated from teams_participants (20260320011304 renamed the
#     legacy teams_users to teams_participants, but the app needs both tables)
#   * join_team_requests single-letter statuses translated to the word values
#     the app expects (ACCEPTED / DECLINED / PENDING / WAITING)
#   * the `score_views` MySQL view (used by ScoreView#questionnaire_data) is
#     rebuilt against the renamed tables/columns
#
# Every statement is guarded, so this migration is a no-op on a database built
# from the original 2023-2025 chain.
class FinishLegacyExpertizaMigration < ActiveRecord::Migration[8.0]
  def up
    rename_legacy_tables
    finish_users
    finish_items
    finish_teams
    finish_duties
    finish_review_grades
    finish_teams_users
    finish_join_team_requests
    recreate_score_views
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def rename_legacy_tables
    rename_table :questions, :items if table_exists?(:questions) && !table_exists?(:items)
    rename_table :sign_up_topics, :project_topics if table_exists?(:sign_up_topics) && !table_exists?(:project_topics)
    rename_table :question_advices, :question_advice if table_exists?(:question_advices) && !table_exists?(:question_advice)
    rename_table :bids, :topic_bids if table_exists?(:bids) && !table_exists?(:topic_bids)
    rename_table :teams_users, :teams_participants if table_exists?(:teams_users) && !table_exists?(:teams_participants)
  end

  # Legacy Expertiza stored the display name in `fullname`; the reimplementation
  # expects it in `name`. (20260320011304 already moved legacy `name` to
  # `username`, so `name` is free at this point.)
  def finish_users
    if column_exists?(:users, :fullname) && !column_exists?(:users, :name)
      rename_column :users, :fullname, :name
    end
  end

  def finish_items
    add_column :items, :question_type, :string unless column_exists?(:items, :question_type)
    # Legacy items carry their STI class in `type`; the app reads question_type.
    execute "UPDATE items SET question_type = type WHERE question_type IS NULL AND type IS NOT NULL"
    add_column :items, :created_at, :datetime unless column_exists?(:items, :created_at)
    add_column :items, :updated_at, :datetime unless column_exists?(:items, :updated_at)
  end

  def finish_teams
    add_column :teams, :created_at, :datetime unless column_exists?(:teams, :created_at)
    add_column :teams, :updated_at, :datetime unless column_exists?(:teams, :updated_at)
  end

  # Legacy Expertiza linked a duty to a single assignment via
  # duties.assignment_id; the reimplementation uses the assignments_duties join
  # table and duties.instructor_id. Translate the (few) legacy rows.
  def finish_duties
    if table_exists?(:assignments_duties) && column_exists?(:duties, :assignment_id)
      execute <<~SQL.squish
        INSERT IGNORE INTO assignments_duties (assignment_id, duty_id, created_at, updated_at)
        SELECT d.assignment_id, d.id, NOW(), NOW()
        FROM duties d
        WHERE d.assignment_id IS NOT NULL
      SQL
    end

    if column_exists?(:duties, :instructor_id) && column_exists?(:assignments, :instructor_id)
      execute <<~SQL.squish
        UPDATE duties d
        JOIN assignments a ON a.id = d.assignment_id
        SET d.instructor_id = a.instructor_id
        WHERE d.instructor_id IS NULL AND a.instructor_id IS NOT NULL
      SQL
    end
  end

  def finish_review_grades
    add_column :review_grades, :grader_id, :integer unless column_exists?(:review_grades, :grader_id)
    add_column :review_grades, :created_at, :datetime unless column_exists?(:review_grades, :created_at)
    add_column :review_grades, :updated_at, :datetime unless column_exists?(:review_grades, :updated_at)
    # The app treats reviewer grades as floats; legacy stored integers.
    execute "ALTER TABLE review_grades MODIFY COLUMN grade_for_reviewer FLOAT NULL"
  end

  # Recreate the teams_users table the Team/TeamsUser models rely on.
  # 20260320011304 renamed the legacy teams_users to teams_participants, so on
  # a legacy database teams_users is missing entirely; on a database built from
  # the original chain it already exists and this is skipped.
  def finish_teams_users
    return if table_exists?(:teams_users)

    return unless table_exists?(:teams_participants)

    create_table :teams_users do |t|
      t.bigint :team_id, null: false
      t.bigint :user_id, null: false
      t.timestamps
    end
    add_index :teams_users, :team_id
    add_index :teams_users, :user_id
    execute <<~SQL.squish
      INSERT IGNORE INTO teams_users (team_id, user_id, created_at, updated_at)
      SELECT tp.team_id, tp.user_id, NOW(), NOW()
      FROM teams_participants tp
      WHERE tp.team_id IS NOT NULL AND tp.user_id IS NOT NULL
    SQL
  end

  # Legacy Expertiza stored the join-team reply as a single letter; the app
  # (JoinTeamRequest) works with word values.
  def finish_join_team_requests
    return unless column_exists?(:join_team_requests, :reply_status) && column_exists?(:join_team_requests, :status)

    execute <<~SQL.squish
      UPDATE join_team_requests
      SET reply_status = CASE status
                            WHEN 'A' THEN 'ACCEPTED'
                            WHEN 'D' THEN 'DECLINED'
                            WHEN 'P' THEN 'PENDING'
                            WHEN 'W' THEN 'WAITING'
                            ELSE NULL
                          END
      WHERE status IN ('A', 'D', 'P', 'W')
    SQL
  end

  # The legacy `score_views` view is defined against the pre-rename table and
  # column names (questions / answers.question_id). Rebuild it on the new names
  # so weighted quiz scoring (ScoreView.questionnaire_data) keeps working.
  # NOTE: no DEFINER clause on purpose — a hardcoded `root`@`localhost` definer
  # breaks `rake db:migrate` in environments where that account (or the SUPER
  # privilege) does not exist. Without the clause MySQL uses the importing
  # user as the definer, which is portable across environments.
  def recreate_score_views
    return unless table_exists?(:items) && column_exists?(:answers, :item_id) && table_exists?(:questionnaires)

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
end
