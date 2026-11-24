# frozen_string_literal: true

# DatabaseCleaner's suite-start clean (spec/rails_helper.rb) wipes every
# table, including the legacy reference/lookup tables that parts of the app
# and the specs rely on with fixed legacy ids. `due_date_spec` creates due
# dates with `deadline_type_id: 3` and `submission_allowed_id` /
# `review_allowed_id: 3` (foreign keys to deadline_types and
# deadline_rights), and the DueDate model maps deadline_type ids to stage
# names.
#
# This module re-seeds those rows with the same ids/names a legacy-migrated
# database carries (see the dev database), using INSERT ... ON DUPLICATE so
# it is safe to run repeatedly.
module SpecReferenceData
  DEADLINE_TYPES = {
    1 => 'submission',
    2 => 'review',
    3 => 'author_feedback',
    4 => 'teammate_review',
    5 => 'metareview',
    6 => 'drop_topic',
    7 => 'signup',
    8 => 'team_formation',
    10 => 'team_formation',
    11 => 'quiz',
    13 => 'bidding_for_topics',
    14 => 'bidding_for_reviews',
    99 => 'other'
  }.freeze

  DEADLINE_RIGHTS = {
    1 => 'No',
    2 => 'Late',
    3 => 'OK'
  }.freeze

  # The reimplementation's duties table (created by 20260209004302 on a
  # legacy-migrated database) is empty, but specs reference duties by their
  # fixed ids (teams_participants_controller_spec updates duty_id: 2, a
  # foreign key to duties.id). instructor_id is nullable, so these rows do
  # not need a backing user.
  DUTIES = {
    1 => 'Scrum master',
    2 => 'Reviewer'
  }.freeze

  def self.seed!
    connection = ActiveRecord::Base.connection
    seed_table!(connection, :deadline_types, DEADLINE_TYPES)
    seed_table!(connection, :deadline_rights, DEADLINE_RIGHTS)
    seed_duties!(connection)
  end

  def self.seed_duties!(connection)
    return unless connection.table_exists?(:duties)

    DUTIES.each do |id, name|
      connection.execute(
        "INSERT INTO duties (id, name, created_at, updated_at) " \
        "VALUES (#{id}, " \
        "#{connection.quote(name)}, NOW(), NOW())" \
        ' ON DUPLICATE KEY UPDATE name = VALUES(name)'
      )
    end
  end

  def self.seed_table!(connection, table, rows)
    return unless connection.table_exists?(table)

    rows.each do |id, name|
      connection.execute(
        "INSERT INTO #{table} (id, name) VALUES (#{id}, '#{name}')" \
        " ON DUPLICATE KEY UPDATE name = VALUES(name)"
      )
    end
  end
end
