# frozen_string_literal: true

# Prepares a freshly imported legacy Expertiza database so that the guarded 2026
# bridge migrations (and the application itself) can run on top of it.
#
# The legacy dump already contains most of the tables the 2023-2025 chain would
# create, so those migrations are marked as applied (see db/migrate_legacy_db.sh
# / .ps1) and never run. This migration backfills the small number of schema
# pieces the 2026 chain expects to exist, in the exact order they are needed:
#
#   * 20260209004302 adds a foreign key duties.instructor_id -> users, which
#     requires duties.instructor_id to exist first.
#   * 20260320011304 renames users.name -> users.username, which would fail if
#     the display-name column (legacy `fullname`) were not handled first.
#
# Every statement is guarded by table/column existence checks, which makes this
# migration a complete no-op on a database built from the original 2023-2025
# chain, so it is safe to keep in the repository for both worlds.
class PrepareLegacyExpertizaSchema < ActiveRecord::Migration[8.0]
  def up
    prepare_users
    prepare_duties
    prepare_signed_up_teams
    prepare_participants
    prepare_join_team_requests
    prepare_answers
    prepare_assignments_duties
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # has_secure_password requires password_digest; the legacy Expertiza users
  # table only carries crypted_password/password_salt (kept for reference).
  def prepare_users
    return unless table_exists?(:users)

    add_column :users, :password_digest, :string unless column_exists?(:users, :password_digest)

    # The legacy table stores the timezone preference in a lowercase column.
    if column_exists?(:users, "timezonepref") && !column_exists?(:users, :time_zone_pref)
      rename_column :users, "timezonepref", :time_zone_pref
    end
  end

  # 20260209004302 (create_assignments_duties_and_duties) adds the foreign key
  # duties.instructor_id -> users.id; the legacy duties table has neither
  # instructor_id nor the `private` flag used by the reimplementation.
  def prepare_duties
    # `duties` does not exist on a database built from the original 2023-2025
    # chain until 20260209004302 creates it, and this migration runs before
    # that; guard on table existence (column_exists? is false for a missing
    # table, which would otherwise let add_column hit "table doesn't exist").
    return unless table_exists?(:duties)

    add_column :duties, :instructor_id, :integer unless column_exists?(:duties, :instructor_id)
    add_column :duties, :private, :boolean, default: false unless column_exists?(:duties, :private)
  end

  # Legacy signed_up_teams.topic_id becomes project_topic_id
  # (20250321222753), and the advertisement fields come from 20251029071649.
  def prepare_signed_up_teams
    return unless table_exists?(:signed_up_teams)

    if column_exists?(:signed_up_teams, :topic_id) && !column_exists?(:signed_up_teams, :project_topic_id)
      rename_column :signed_up_teams, :topic_id, :project_topic_id
    end
    if column_exists?(:signed_up_teams, :sign_up_topic_id) && !column_exists?(:signed_up_teams, :project_topic_id)
      rename_column :signed_up_teams, :sign_up_topic_id, :project_topic_id
    end
    add_column :signed_up_teams, :comments_for_advertisement, :text unless column_exists?(:signed_up_teams, :comments_for_advertisement)
    add_column :signed_up_teams, :advertise_for_partner, :boolean unless column_exists?(:signed_up_teams, :advertise_for_partner)
    add_column :signed_up_teams, :created_at, :datetime unless column_exists?(:signed_up_teams, :created_at)
    add_column :signed_up_teams, :updated_at, :datetime unless column_exists?(:signed_up_teams, :updated_at)
  end

  # Columns the reimplementation expects on participants that the legacy table
  # does not carry (team membership, topic, stage tracking, ...).
  def prepare_participants
    return unless table_exists?(:participants)

    add_column :participants, :team_id, :bigint unless column_exists?(:participants, :team_id)
    add_column :participants, :topic, :string unless column_exists?(:participants, :topic)
    add_column :participants, :authorization, :string unless column_exists?(:participants, :authorization)
    add_column :participants, :current_stage, :string unless column_exists?(:participants, :current_stage)
    add_column :participants, :stage_deadline, :datetime unless column_exists?(:participants, :stage_deadline)
    add_column :participants, :join_team_request_id, :bigint unless column_exists?(:participants, :join_team_request_id)
    add_column :participants, :created_at, :datetime unless column_exists?(:participants, :created_at)
    add_column :participants, :updated_at, :datetime unless column_exists?(:participants, :updated_at)
  end

  # The app works with reply_status (20250805174104 renamed status ->
  # reply_status in the original chain); the legacy table still has `status`.
  def prepare_join_team_requests
    return unless table_exists?(:join_team_requests)

    add_column :join_team_requests, :reply_status, :string unless column_exists?(:join_team_requests, :reply_status)
  end

  # 20250621180527 renamed answers.question_id -> answers.item_id.
  def prepare_answers
    return unless table_exists?(:answers)

    if column_exists?(:answers, :question_id) && !column_exists?(:answers, :item_id)
      rename_column :answers, :question_id, :item_id
    end
  end

  # The legacy Expertiza schema uses INT primary keys, whereas the
  # reimplementation creates new reference columns as BIGINT (Rails default).
  # MySQL foreign keys require the referencing and referenced columns to have
  # identical types, so `assignments_duties` (created by 20260209004302 with
  # BIGINT columns) cannot reference the legacy INT assignments.id / duties.id.
  #
  # When the database still has INT primary keys (i.e. it came from the legacy
  # dump), create/normalize `assignments_duties` with INT reference columns so
  # the foreign keys added by 20260209004302 succeed. On a database built from
  # the original 2023-2025 chain the primary keys are BIGINT, this block is a
  # no-op, and 20260209004302 creates the table with its normal BIGINT columns.
  def prepare_assignments_duties
    return unless table_exists?(:assignments)

    pk_type =
      select_value(
        "SELECT COLUMN_TYPE FROM information_schema.columns " \
        "WHERE table_schema = DATABASE() AND table_name = 'assignments' AND column_name = 'id'"
      ).to_s

    return unless pk_type.start_with?("int") && !pk_type.start_with?("bigint")

    if table_exists?(:assignments_duties)
      execute "ALTER TABLE assignments_duties MODIFY assignment_id INT NOT NULL, MODIFY duty_id INT NOT NULL"
    else
      create_table :assignments_duties do |t|
        t.integer :assignment_id, null: false
        t.integer :duty_id, null: false
        t.timestamps
      end
    end
  end
end
