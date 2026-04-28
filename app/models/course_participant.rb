# frozen_string_literal: true

require 'csv'

class CourseParticipant < Participant
  extend ImportableExportableHelper

  PARTICIPANT_IMPORT_EXPORT_FIELDS = %w[
    user_name
  ].freeze

  mandatory_fields :user_name
  available_actions_on_duplicate SkipRecordAction.new, UpdateExistingRecordAction.new
  filter -> { export_scope }

  belongs_to :user
  validates :handle, presence: true

  def user_name
    user&.name
  end

  def set_handle
    # Normalize the user's preferred handle.
    desired = user.handle.to_s.strip

    self.handle =
      if desired.empty?
        user.name
      elsif CourseParticipant.exists?(parent_id: course.id, handle: desired)
        user.name
      else
        desired
      end

    save
  end

  class << self
    # Course participants are existing users attached to a course. Keep the CSV
    # surface narrow so imports cannot accidentally create or edit users.
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

    def with_course_context(course_id, current_user = nil)
      previous_course_id = import_export_course_id
      previous_current_user = import_export_current_user
      self.import_export_course_id = course_id
      self.import_export_current_user = current_user
      yield
    ensure
      self.import_export_course_id = previous_course_id
      self.import_export_current_user = previous_current_user
    end

    def try_import_records(file, headers, use_header, _defaults = {})
      course_id = import_export_course_id
      raise StandardError, 'course_id is required for course participant import' if course_id.blank?
      raise StandardError, "Course '#{course_id}' was not found." unless Course.exists?(course_id)

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
          import_participant_row(row, mapping, course_id)
        end
      end

      []
    end

    private

    def validate_import_mapping!(mapping)
      missing_fields = mandatory_fields - mapping.ordered_fields
      return if missing_fields.empty?

      raise StandardError, "Missing mandatory course participant fields: #{missing_fields.join(', ')}"
    end

    def import_participant_row(row, mapping, course_id)
      row_hash = {}
      mapping.ordered_fields.zip(row).each do |key, value|
        row_hash[key] = value
      end

      user = find_import_user(row_hash)
      participant = find_or_initialize_by(
        parent_id: course_id,
        user_id: user.id,
        type: name
      )

      participant.handle = participant.handle.presence || user.handle.presence || user.name
      participant.save!
    end

    def find_import_user(row_hash)
      username = row_hash['user_name'].to_s.strip
      user = User.find_by(name: username)
      return user if user

      raise StandardError, "User '#{username}' was not found. Course participant import expects existing users."
    end

    def export_scope
      scope = includes(:user).where(type: name)
      import_export_course_id.present? ? scope.where(parent_id: import_export_course_id) : scope
    end

    def import_export_course_id
      Thread.current[:course_participant_import_export_course_id]
    end

    def import_export_course_id=(course_id)
      Thread.current[:course_participant_import_export_course_id] = course_id.presence&.to_i
    end

    def import_export_current_user
      Thread.current[:course_participant_import_export_current_user]
    end

    def import_export_current_user=(user)
      Thread.current[:course_participant_import_export_current_user] = user
    end
  end
end
