# frozen_string_literal: true

require 'csv'

class AssignmentParticipant < Participant
  extend ImportableExportableHelper
  include ReviewAggregator
  PARTICIPANT_IMPORT_EXPORT_FIELDS = %w[
    user_name
  ].freeze

  mandatory_fields :user_name
  available_actions_on_duplicate SkipRecordAction.new, UpdateExistingRecordAction.new
  filter -> { export_scope }

  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'from_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :response_maps, foreign_key: 'reviewee_id'
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'from_id'
  belongs_to :duty, optional: true
  belongs_to :user
  validates :handle, presence: true

  # Delegation methods to avoid Law of Demeter violations
  delegate :name, to: :user, prefix: true, allow_nil: true
  delegate :id, to: :team, prefix: true, allow_nil: true
  delegate :id, to: :assignment, prefix: true, allow_nil: true
  delegate :path, to: :team, prefix: true, allow_nil: true

  # Fetches the team for specific participant
  def team
    AssignmentTeam.team(self)
  end

  # Fetches Assignment Directory.
  def dir_path
    assignment.try :directory_path
  end

  # Gets the student directory path
  def path
    "#{assignment.path}/#{team.directory_num}"
  end
    
  def retract_sent_invitations
    sent_invitations.each(&:retract)
  end

  def set_handle
    self.handle = if user.handle.nil? || (user.handle == '')
                    user.name
                  elsif Participant.exists?(assignment_id: assignment.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    self.save
  end

  def retract_sent_invitations
    sent_invitations.each(&:retract)
  end

  def aggregate_teammate_review_grade(teammate_review_mappings)
    compute_average_review_score(teammate_review_mappings)
  end

  def user_name
    user&.name
  end

  class << self
    # Import/export exposes a deliberately small CSV surface. Assignment
    # participants are existing users attached to an assignment, so the CSV
    # should identify the user and avoid editing user profile data.
    def internal_fields
      PARTICIPANT_IMPORT_EXPORT_FIELDS
    end

    def optional_fields
      PARTICIPANT_IMPORT_EXPORT_FIELDS - mandatory_fields
    end

    def external_fields
      []
    end

    def internal_and_external_fields
      internal_fields
    end

    # The shared import/export controllers are model-oriented, but assignment
    # participants must be scoped to one assignment. Store that request context
    # for the duration of the import/export operation.
    def with_assignment_context(assignment_id, current_user = nil)
      previous_assignment_id = import_export_assignment_id
      previous_current_user = import_export_current_user
      self.import_export_assignment_id = assignment_id
      self.import_export_current_user = current_user
      yield
    ensure
      self.import_export_assignment_id = previous_assignment_id
      self.import_export_current_user = previous_current_user
    end

    # Import a username-only CSV and attach each existing user to the current
    # assignment. This intentionally does not create or update User records.
    def try_import_records(file, headers, use_header, _defaults = {})
      assignment_id = import_export_assignment_id
      raise StandardError, 'assignment_id is required for participant import' if assignment_id.blank?

      csv_table = CSV.read(file, headers: use_header)
      normalized_headers =
        if use_header
          csv_table.headers.map { |header| header.to_s.parameterize.underscore }
        else
          Array(headers).map { |header| header.to_s.parameterize.underscore }
        end

      mapping = FieldMapping.from_header(self, normalized_headers)
      validate_import_mapping!(mapping)
      rows = use_header ? csv_table.map(&:fields) : csv_table

      ActiveRecord::Base.transaction do
        rows.each do |row|
          import_participant_row(row, mapping, assignment_id)
        end
      end

      []
    end

    private

    # Keep the CSV contract explicit so a missing or misspelled username column
    # fails before any participants are changed.
    def validate_import_mapping!(mapping)
      missing_fields = mandatory_fields - mapping.ordered_fields
      return if missing_fields.empty?

      raise StandardError, "Missing mandatory participant fields: #{missing_fields.join(', ')}"
    end

    # Create the assignment participant link for the resolved user, or reuse the
    # existing participant if the user is already attached to this assignment.
    def import_participant_row(row, mapping, assignment_id)
      row_hash = {}
      mapping.ordered_fields.zip(row).each do |key, value|
        row_hash[key] = value
      end

      user = find_import_user(row_hash)
      participant = find_or_initialize_by(
        parent_id: assignment_id,
        user_id: user.id,
        type: name
      )

      participant.handle = row_hash['handle'].presence || participant.handle || user.name
      participant.save!
    end

    # Username import is a lookup, not a user creation path. This prevents an
    # instructor import from accidentally adding malformed or duplicate users.
    def find_import_user(row_hash)
      username = row_hash['user_name'].to_s.strip
      user = User.find_by(name: username)
      return user if user

      raise StandardError, "User '#{username}' was not found. Assignment participant import expects existing users."
    end

    # Export only assignment participants in the active assignment context when
    # one is provided by the controller.
    def export_scope
      scope = includes(:user).where(type: name)
      import_export_assignment_id.present? ? scope.where(parent_id: import_export_assignment_id) : scope
    end

    def import_export_assignment_id
      Thread.current[:assignment_participant_import_export_assignment_id]
    end

    def import_export_assignment_id=(assignment_id)
      Thread.current[:assignment_participant_import_export_assignment_id] = assignment_id.presence&.to_i
    end

    def import_export_current_user
      Thread.current[:assignment_participant_import_export_current_user]
    end

    def import_export_current_user=(user)
      Thread.current[:assignment_participant_import_export_current_user] = user
    end
  end
end
