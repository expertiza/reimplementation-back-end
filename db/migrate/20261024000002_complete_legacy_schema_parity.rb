# frozen_string_literal: true

# Completes the legacy schema so the application behaves the same on a
# legacy-migrated database as on one built from the 2023-2026 chain.
#
#   * assignments.has_topics          (boolean, default false; 20231129051018)
#   * account_requests.full_name      (string; 20230412013301; legacy stored it as `fullname`)
#   * account_requests.introduction   (text; 20230412013301; legacy stored it as `self_introduction`)
#   * items.break_before              (nullable, no default; the legacy DEFAULT 1 leaked
#                                     into new records and defeated the presence validation)
#   * review_grades                   (drop review_graded_at / reviewer_id, which the
#                                     reimplementation's clean schema does not have)
#   * signed_up_teams                   (project_topic_id / team_id widened int ->
#                                       bigint to match the canonical foreign keys; the
#                                       legacy "0 = no topic/team" sentinel is NULLed by
#                                       20261101000004)
#   * all tables                      (latin1 -> utf8mb4; the legacy character set rejects
#                                     multi-byte unicode such as emoji in comments)
#
# Every statement is guarded, so this migration is a no-op on a database
# built from the original chain.
class CompleteLegacySchemaParity < ActiveRecord::Migration[8.0]
  def up
    add_has_topics
    add_account_request_columns
    # MariaDB refuses to re-define a column that is part of a foreign key
    # (errno 1832) while the constraint is in place - a CONVERT TO CHARACTER
    # SET re-defines every string column, and so do the normalizations below.
    # MySQL keeps or silently drops such constraints, which is why this was
    # only ever visible on MariaDB. Detach every foreign key for the duration
    # of the schema rewrites, then restore whatever is still valid; the
    # convergence migration re-creates the canonical foreign keys either way.
    detach_foreign_keys
    begin
      convert_tables_to_utf8mb4
      normalize_items_break_before
      drop_review_grade_legacy_columns
      normalize_signed_up_teams
    ensure
      readd_foreign_keys
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def add_has_topics
    return unless table_exists?(:assignments)

    add_column :assignments, :has_topics, :boolean, default: false unless column_exists?(:assignments, :has_topics)
  end

  def add_account_request_columns
    return unless table_exists?(:account_requests)

    add_column :account_requests, :full_name, :string unless column_exists?(:account_requests, :full_name)
    add_column :account_requests, :introduction, :text unless column_exists?(:account_requests, :introduction)

    # Backfill from the legacy column names where the values live there.
    if column_exists?(:account_requests, :full_name) && column_exists?(:account_requests, :fullname)
      execute "UPDATE account_requests SET full_name = fullname WHERE full_name IS NULL AND fullname IS NOT NULL AND fullname <> ''"
    end
    if column_exists?(:account_requests, :introduction) && column_exists?(:account_requests, :self_introduction)
      execute "UPDATE account_requests SET introduction = self_introduction WHERE introduction IS NULL AND self_introduction IS NOT NULL AND self_introduction <> ''"
    end
  end

  def normalize_items_break_before
    return unless table_exists?(:items) && column_exists?(:items, :break_before)

    execute 'ALTER TABLE items MODIFY COLUMN break_before tinyint(1) NULL'
  end

  def drop_review_grade_legacy_columns
    return unless table_exists?(:review_grades)

    remove_column :review_grades, :review_graded_at if column_exists?(:review_grades, :review_graded_at)
    remove_column :review_grades, :reviewer_id if column_exists?(:review_grades, :reviewer_id)
  end

  def normalize_signed_up_teams
    return unless table_exists?(:signed_up_teams)

    %i[project_topic_id team_id].each do |column|
      col = columns(:signed_up_teams).find { |c| c.name == column.to_s }
      next unless col

      # The legacy schema had these as `int NOT NULL DEFAULT 0` (a "no topic
      # / no team" sentinel). Clean chain DBs already have the canonical
      # bigint shape (required for the foreign keys), so rewrite only
      # legacy-width columns and to bigint, keeping any foreign key
      # type-compatible. (20261101000001 later makes them NULL to express
      # "none" on both shapes.)
      execute "ALTER TABLE signed_up_teams MODIFY COLUMN #{column} bigint NOT NULL" unless col.bigint?
    end
  end

  def convert_tables_to_utf8mb4
    # Convert every table that is not already on the canonical
    # utf8mb4/general_ci combination. utf8mb4_general_ci is used (rather
    # than the MySQL-only utf8mb4_0900_ai_ci) so the canonical schema works
    # on both MySQL 8.x and MariaDB 10.x/11.x. Tables already on the target
    # combination are skipped (a CONVERT on an already-converted table is a
    # full rewrite for no change).
    rows = select_values(
      'SELECT TABLE_NAME FROM information_schema.TABLES ' \
      'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_COLLATION IS NOT NULL ' \
      "AND TABLE_COLLATION <> 'utf8mb4_general_ci'"
    )
    rows.each do |table|
      execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    end
  end

  # Drop every foreign key in the current schema, remembering how to
  # recreate each one (used by detach_foreign_keys / readd_foreign_keys).
  # Idempotent: on a re-run after an interrupted migration there is simply
  # nothing left to drop.
  def detach_foreign_keys
    @foreign_keys = select_all(
      'SELECT TABLE_NAME, CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME ' \
      'FROM information_schema.KEY_COLUMN_USAGE ' \
      'WHERE TABLE_SCHEMA = DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL'
    ).group_by { |row| [row['TABLE_NAME'], row['CONSTRAINT_NAME']] }

    @foreign_keys.each do |(table, name), _rows|
      execute "ALTER TABLE #{table} DROP FOREIGN KEY `#{name}`"
    end
  end

  # Recreate the constraints remembered by detach_foreign_keys, skipping
  # any that no longer validate (their columns or the referenced column
  # changed type/character set incompatibly while detached) and any that
  # were re-created in the meantime. The convergence migration re-creates
  # the canonical foreign keys, so a skipped legacy constraint is not a
  # loss. Safe to call twice (the ensure and the end of up).
  def readd_foreign_keys
    return unless @foreign_keys

    begin
      @foreign_keys.each do |(table, name), rows|
        exists = select_value(
          'SELECT COUNT(*) FROM information_schema.REFERENTIAL_CONSTRAINTS ' \
          "WHERE CONSTRAINT_SCHEMA = DATABASE() AND CONSTRAINT_NAME = '#{name}' " \
          "AND TABLE_NAME = '#{table}'"
        )
        next if exists.to_i.positive?

        cols = rows.map { |row| "`#{row['COLUMN_NAME']}`" }.join(', ')
        refs = rows.map { |row| "`#{row['REFERENCED_TABLE_NAME']}` (`#{row['REFERENCED_COLUMN_NAME']}`)" }.uniq.join(', ')
        begin
          execute "ALTER TABLE #{table} ADD CONSTRAINT `#{name}` FOREIGN KEY (#{cols}) REFERENCES #{refs}"
        rescue Mysql2::Error
          # Column/character-set drift made this legacy constraint
          # unrecoverable; the application does not depend on it.
        end
      end
    ensure
      @foreign_keys = nil
    end
  end
end
