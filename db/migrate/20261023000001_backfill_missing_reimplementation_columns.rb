# frozen_string_literal: true

# Backfills the reimplementation schema columns that a legacy-migrated
# Expertiza database is missing. The 2023-2025 migration chain added these
# columns on a database built from scratch, but the legacy-migration
# sequence (20260101000000_prepare_legacy_expertiza_schema /
# 20261023000000_finish_legacy_expertiza_migration) recorded those versions
# in schema_migrations WITHOUT running their DDL, so the columns never
# materialized on a migrated database. The application models, controllers
# and specs all rely on them:
#
#   * assignments.has_teams        (boolean, default false)
#   * assignments.vary_by_round    (boolean, default false, null: false)
#   * questionnaires.questionnaire_type  (string; full class name, e.g. 'ReviewQuestionnaire')
#   * account_requests.username    (string; the requested login name)
#   * due_dates.parent_type        (string; polymorphic parent for DueDate#parent)
#   * ta_mappings.user_id          (integer; the TA's user id)
#   * teams_participants.created_at / updated_at (datetime)
#
# It also drops the legacy foreign keys on invitations.from_id / to_id that
# point at users.id; the reimplementation stores participant ids in those
# columns (see app/models/invitation.rb).
#
# Every statement is guarded, so this migration is a no-op on a database
# built from the original 2023-2025 chain.
class BackfillMissingReimplementationColumns < ActiveRecord::Migration[8.0]
  def up
    backfill_assignments
    backfill_questionnaires
    backfill_account_requests
    backfill_due_dates
    backfill_ta_mappings
    backfill_teams_participants
    fix_invitation_foreign_keys
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def backfill_assignments
    add_column :assignments, :has_teams, :boolean, default: false unless column_exists?(:assignments, :has_teams)
    add_column :assignments, :vary_by_round, :boolean, default: false, null: false unless column_exists?(:assignments, :vary_by_round)
  end

  def backfill_questionnaires
    # Legacy rows carry a zero-date default ('0000-00-00 00:00:00') on
    # updated_at, which makes any ALTER TABLE on questionnaires fail under
    # strict sql_mode. Normalize it to a plain nullable datetime first
    # (matching the clean 2023-chain schema). Zero dates are a legacy
    # artifact, so this only applies to legacy-migrated databases.
    execute "ALTER TABLE questionnaires MODIFY COLUMN updated_at datetime NULL" if legacy_source?
    add_column :questionnaires, :questionnaire_type, :string unless column_exists?(:questionnaires, :questionnaire_type)

    # The legacy Expertiza schema stored the questionnaire class in the STI
    # `type` column; the reimplementation reads `questionnaire_type`. A clean
    # chain database has no `type` column, so guard on its presence.
    execute "UPDATE questionnaires SET questionnaire_type = type WHERE questionnaire_type IS NULL AND type IS NOT NULL" if column_exists?(:questionnaires, :type)

    # Fall back to display_type ('Review', 'Author Feedback', ...) for rows
    # whose type is NULL/blank, normalizing to the full class-name form the
    # app expects (e.g. 'ReviewQuestionnaire').
    if column_exists?(:questionnaires, :display_type)
      execute <<~SQL.squish
        UPDATE questionnaires
        SET questionnaire_type = CONCAT(display_type, 'Questionnaire')
        WHERE questionnaire_type IS NULL
          AND display_type IS NOT NULL AND display_type <> ''
      SQL
    end
  end

  def backfill_account_requests
    add_column :account_requests, :username, :string unless column_exists?(:account_requests, :username)

    # Legacy stored the requested username in `name`; the app uses `username`.
    # A clean chain database has no `name` column, so guard on its presence.
    execute "UPDATE account_requests SET username = name WHERE username IS NULL AND name IS NOT NULL AND name <> ''" if column_exists?(:account_requests, :name)
  end

  def backfill_due_dates
    # DueDate uses a polymorphic `belongs_to :parent` with foreign_key
    # 'assignment_id', which requires a parent_type discriminator column.
    # Legacy rows always belong to an Assignment.
    add_column :due_dates, :parent_type, :string unless column_exists?(:due_dates, :parent_type)
    execute "UPDATE due_dates SET parent_type = 'Assignment' WHERE parent_type IS NULL"
  end

  def backfill_ta_mappings
    # The app's TaMapping model keys the TA by user_id (belongs_to :ta,
    # foreign_key: 'user_id'); legacy stored the same value in ta_id.
    add_column :ta_mappings, :user_id, :integer unless column_exists?(:ta_mappings, :user_id)
    add_index :ta_mappings, :user_id, name: 'index_ta_mappings_on_user_id' unless index_exists?(:ta_mappings, :user_id, name: 'index_ta_mappings_on_user_id')
    # A clean chain database has no legacy `ta_id` column, so guard on it.
    execute "UPDATE ta_mappings SET user_id = ta_id WHERE user_id IS NULL AND ta_id IS NOT NULL" if column_exists?(:ta_mappings, :ta_id)
  end

  def backfill_teams_participants
    add_column :teams_participants, :created_at, :datetime unless column_exists?(:teams_participants, :created_at)
    add_column :teams_participants, :updated_at, :datetime unless column_exists?(:teams_participants, :updated_at)
    execute "UPDATE teams_participants SET created_at = NOW() WHERE created_at IS NULL"
    execute "UPDATE teams_participants SET updated_at = NOW() WHERE updated_at IS NULL"
  end

  def fix_invitation_foreign_keys
    # The reimplementation stores participant ids in from_id/to_id, so the
    # legacy FKs to users.id must be removed (a clean DB never had them).
    if foreign_key_exists?(:invitations, column: :from_id, name: :fk_invitationfrom_users)
      remove_foreign_key :invitations, column: :from_id, name: :fk_invitationfrom_users
    end
    if foreign_key_exists?(:invitations, column: :to_id, name: :fk_invitationto_users)
      remove_foreign_key :invitations, column: :to_id, name: :fk_invitationto_users
    end
  end

  # A legacy Expertiza DB still has tables the canonical chain never creates;
  # the canonical chain has none of them.
  def legacy_source?
    %w[sessions goldberg_roles goldberg_users versions
       review_strategies reviews automated_metareviews
       assignments_questionnaires].any? { |t| table_exists?(t) }
  end
end