# frozen_string_literal: true

# Normalizes legacy column defaults that leak into new records and break
# application semantics.
#
# On a database built from the 2023-2025 chain these columns are plain
# nullable columns with no default (e.g. `t.string :min_label`,
# `t.integer :max_team_size`), so a freshly built record carries `nil`.
# The legacy Expertiza schema instead shipped `DEFAULT ''` (strings) and
# `NOT NULL DEFAULT 0` (integers). Rails initializes new-record attributes
# from the schema defaults, which silently changes behavior:
#
#   * items.min_label / max_label / size   -> new items serialize "" instead of nil
#   * assignments.max_team_size            -> 0 is truthy, so Team#full? is always
#                                             true (0 >= 0) and members can never join
#   * signed_up_teams.project_topic_id / team_id
#                                          -> new records get 0 instead of nil, which
#                                             bypasses the belongs_to "must exist"
#                                             validation (Rails 8 keeps
#                                             belongs_to_required_validates_foreign_key
#                                             = false, so the check only fires for a nil FK)
#
# This migration rewrites the definitions to match the clean chain. It is a
# no-op on a database built from the original 2023-2025 chain (the column
# already matches the target definition) and only touches databases that
# were migrated from the legacy Expertiza schema.
class NormalizeLegacyColumnDefaults < ActiveRecord::Migration[8.0]
  def up
    normalize_items
    normalize_max_team_size
    normalize_signed_up_teams
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def normalize_items
    %i[min_label max_label size].each do |column|
      next unless column_exists?(:items, column)

      execute "ALTER TABLE items MODIFY COLUMN #{column} varchar(255) NULL"
    end
  end

  def normalize_max_team_size
    { assignments: true, courses: true }.each do |table, present|
      next unless present && table_exists?(table) && column_exists?(table, :max_team_size)

      execute "ALTER TABLE #{table} MODIFY COLUMN max_team_size int NULL"
    end
  end

  def normalize_signed_up_teams
    return unless table_exists?(:signed_up_teams)

    %i[project_topic_id team_id].each do |column|
      col = columns(:signed_up_teams).find { |c| c.name == column.to_s }
      next unless col
      next if col.bigint?

      # The legacy schema had these as `int NOT NULL DEFAULT 0` (a "no topic
      # / no team" sentinel). Clean chain DBs already have the canonical
      # bigint shape (required for the foreign keys), so this rewrite is only
      # ever needed on a legacy-migrated database, where the columns are still
      # int. (20261101000001 later makes them NULL to express "none".)
      #
      # InnoDB (errno 3780) and MariaDB (errno 1832) refuse to widen a column
      # that participates in a foreign key while the referenced column keeps
      # its old width, so detach the table's foreign keys first. The legacy
      # constraints point at INT primary keys; the parity + convergence
      # migrations recreate the canonical FKs (bigint -> bigint), so the
      # dropped legacy constraints are not a loss.
      drop_signed_up_teams_foreign_keys

      execute "ALTER TABLE signed_up_teams MODIFY COLUMN #{column} bigint NOT NULL"
    end
  end

  # Detach every foreign key on signed_up_teams (idempotent). Only called when
  # a column is still at legacy int width, so it is a no-op on a clean chain
  # database, whose columns are already bigint and never widened here.
  def drop_signed_up_teams_foreign_keys
    select_values(
      "SELECT DISTINCT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE " \
      "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'signed_up_teams' " \
      "AND REFERENCED_TABLE_NAME IS NOT NULL"
    ).each do |name|
      begin
        execute "ALTER TABLE signed_up_teams DROP FOREIGN KEY `#{name}`"
      rescue Mysql2::Error
        # Constraint already gone (interrupted re-run) - nothing to do.
      end
    end
  end
end
