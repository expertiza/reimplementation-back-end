# frozen_string_literal: true

# Backfills the created_at / updated_at timestamp columns that a
# legacy-migrated Expertiza database is missing on a handful of core
# tables. The 2023-2025 migration chain added these columns via
# `t.timestamps` in each table's `create_*` migration, but the legacy
# migration sequence (20260101000000_prepare_legacy_expertiza_schema /
# 20261023000000_finish_legacy_expertiza_migration) records those versions
# in schema_migrations WITHOUT running their DDL, so the timestamp columns
# never materialized on a migrated database.
#
# ApplicationRecord has Rails' implicit timestamps enabled, so saving any of
# these models writes updated_at. On a legacy-migrated database that raises
# `NoMethodError: undefined method 'updated_at='`. The affected tables:
#
#   * answers.created_at / updated_at
#   * users.created_at / updated_at
#   * institutions.created_at / updated_at
#   * invitations.created_at / updated_at
#   * nodes.created_at / updated_at
#   * assignment_questionnaires.created_at / updated_at
#   * suggestion_comments.updated_at   (created_at exists but is nullable; no model)
#
# Every statement is guarded, so this migration is a no-op on a database
# built from the original 2023-2025 chain.
class BackfillMissingTimestampColumns < ActiveRecord::Migration[8.0]
  def up
    backfill_timestamps :answers
    backfill_timestamps :users
    backfill_timestamps :institutions
    backfill_timestamps :invitations
    backfill_timestamps :nodes
    backfill_timestamps :assignment_questionnaires
    backfill_timestamps :suggestion_comments
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def backfill_timestamps(table)
    return unless table_exists?(table)

    add_column table, :created_at, :datetime unless column_exists?(table, :created_at)
    add_column table, :updated_at, :datetime unless column_exists?(table, :updated_at)
    execute "UPDATE #{table} SET created_at = NOW() WHERE created_at IS NULL"
    execute "UPDATE #{table} SET updated_at = NOW() WHERE updated_at IS NULL"
  end
end
