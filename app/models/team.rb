# frozen_string_literal: true

class Team < ApplicationRecord
  extend ImportableExportableHelper
  TEAM_PARTICIPANT_COLUMN_PREFIX = 'participant_'
  DEFAULT_TEAM_IMPORT_EXPORT_PARTICIPANT_COLUMNS = 10
  mandatory_fields :name
  hidden_fields :id, :created_at, :updated_at
  filter -> { export_rows }
  export_submodels false

  TeamExportRow = Struct.new(:team, :participants) do
    def initialize(team, participants)
      super(team, participants)
      self.participants ||= []
    end

    def name
      team.name
    end

    def method_missing(method_name, *_args)
      method = method_name.to_s
      return super unless method.start_with?(TEAM_PARTICIPANT_COLUMN_PREFIX)

      index = method.delete_prefix(TEAM_PARTICIPANT_COLUMN_PREFIX).to_i - 1
      participants[index]&.id
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.start_with?(TEAM_PARTICIPANT_COLUMN_PREFIX) || super
    end
  end

  # Core associations
  has_many :signed_up_teams, dependent: :destroy
  has_many :project_topics, through: :signed_up_teams
  has_many :teams_users, dependent: :destroy
  has_many :teams_participants, dependent: :destroy
  has_many :users, through: :teams_participants
  has_many :participants, through: :teams_participants
  has_many :join_team_requests, dependent: :destroy
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'from_id', dependent: :destroy

  # The team is either an AssignmentTeam or a CourseTeam
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true
  belongs_to :user, optional: true # Team creator

  attr_accessor :max_participants
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentTeam CourseTeam MentoredTeam], message: "must be 'Assignment' or 'Course' or 'Mentor'" }

  after_update :release_topics_if_empty
  before_destroy :clear_participant_team_references

  def has_member?(user)
    participants.exists?(user_id: user.id)
  end

  # Returns the current number of team members
  def team_size
    users.count
  end

  # Returns the maximum allowed team size
  def max_size
    if is_a?(AssignmentTeam) && assignment&.max_team_size
      assignment.max_team_size
    elsif is_a?(CourseTeam) && course&.max_team_size
      course.max_team_size
    else
      nil
    end
  end

  def full?
    current_size = participants.count

    # assignment teams use the column max_team_size
    if is_a?(AssignmentTeam) && assignment&.max_team_size
      return current_size >= assignment.max_team_size
    end

    # course teams never fill up by default
    false
  end

  # Checks if the given participant is already on any team for the associated assignment or course.
  def participant_on_team?(participant)
    # pick the correct “scope” (assignment or course) based on this team’s class
    scope =
      if is_a?(AssignmentTeam)
        assignment
      elsif is_a?(CourseTeam)
        course
      end

    return false unless scope

    # “scope.teams” includes this team itself plus any sibling teams;
    # check whether any of those teams already has this participant
    scope.teams.any? { |team| team.participants.include?(participant) }
  end

  # Adds participant in the team
  def add_member(participant_or_user)
    participant =
      if participant_or_user.is_a?(AssignmentParticipant) || participant_or_user.is_a?(CourseParticipant)
        participant_or_user
      elsif participant_or_user.is_a?(User)
        participant_type = is_a?(AssignmentTeam) ? AssignmentParticipant : CourseParticipant
        participant_type.find_by(user_id: participant_or_user.id, parent_id: parent_id)
      else
        nil
      end

    # If participant wasn't found or built correctly
    return { success: false, error: "#{participant_or_user.name} is not a participant in this #{is_a?(AssignmentTeam) ? 'assignment' : 'course'}" } if participant.nil?

    return { success: false, error: "Participant already on the team" } if participants.exists?(id: participant.id)
    return { success: false, error: "Unable to add participant: team is at full capacity." } if full?

    team_participant = TeamsParticipant.create(
      participant_id: participant.id,
      team_id: id,
      user_id: participant.user_id
    )

    if team_participant.persisted?
      { success: true }
    else
      { success: false, error: team_participant.errors.full_messages.join(', ') }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  # Removes a participant from this team.
  # - Delete the TeamsParticipant join record
  # - if the participant sent any invitations while being on the team, they all need to be retracted
  # - If the team has no remaining members, destroy the team itself
  def remove_member(participant)
    # retract all the invitations the participant sent (if any) while being on the this team
    participant.retract_sent_invitations

    # Remove the join record if it exists
    tp = TeamsParticipant.find_by(team_id: id, participant_id: participant.id)
    tp&.destroy

    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # this will remove the reference only if the participant's current team is the same team removing the participant
    if participant.team_id == id
      participant.update!(team_id: nil)
    end

    # If no participants remain after removal, delete the team
    destroy if participants.empty?
  end

  # Determines whether a given participant is eligible to join the team.
  def can_participant_join_team?(participant)
    # figure out whether we’re in an Assignment or a Course context
    scope, participant_type, label =
      if is_a?(AssignmentTeam)
        [assignment, AssignmentParticipant, "assignment"]
      elsif is_a?(CourseTeam)
        [course, CourseParticipant, "course"]
      else
        return { success: false, error: "Team must belong to Assignment or Course" }
      end

    # Check if the user is already part of any team for this assignment or course
    if participant_on_team?(participant)
      return { success: false, error: "This user is already assigned to a team for this #{label}" }
    end

    # Check if the user is a registered participant for this assignment or course
    registered = participant_type.find_by(
      user_id: participant.user_id,
      parent_id: scope.id
    )

    unless registered
      return { success: false, error: "#{participant.user.name} is not a participant in this #{label}" }
    end

    # All checks passed; participant is eligible to join the team
    { success: true }
  end

  private

  def clear_participant_team_references
    Participant.where(team_id: id).update_all(team_id: nil)
  end

  def release_topics_if_empty
    return unless participants.empty?
    project_topics.each { |topic| topic.drop_team(self) }
  end

  class << self
    def internal_fields
      ['name'] + participant_field_names
    end

    def optional_fields
      participant_field_names
    end

    def external_fields
      []
    end

    def internal_and_external_fields
      internal_fields
    end

    def export_rows
      export_scope.includes(:participants).map do |team|
        TeamExportRow.new(team, team.participants.order(:id).to_a)
      end
    end

    def try_import_records(file, headers, use_header, defaults = {})
      csv_table = CSV.read(file, headers: use_header)
      normalized_headers =
        if use_header
          csv_table.headers.map { |header| header.to_s.parameterize.underscore }
        else
          Array(headers).map { |header| header.to_s.parameterize.underscore }
        end

      mapping = FieldMapping.from_header(self, normalized_headers)
      rows = use_header ? csv_table.map(&:fields) : csv_table

      ActiveRecord::Base.transaction do
        rows.each do |row|
          import_team_row(row, mapping, defaults)
        end
      end

      []
    end

    def with_assignment_context(assignment_id)
      previous_assignment_id = import_export_assignment_id
      self.import_export_assignment_id = assignment_id
      yield
    ensure
      self.import_export_assignment_id = previous_assignment_id
    end

    private

    def import_team_row(row, mapping, defaults)
      row_hash = {}
      mapping.ordered_fields.zip(row).each do |key, value|
        row_hash[key] = value
      end

      team = find_or_build_import_team(row_hash, defaults)
      team.save! if team.new_record? || team.changed?

      participant_ids_from_row(row_hash).each do |participant_id|
        participant = find_import_participant(team, participant_id)
        next unless participant
        next if team.participants.exists?(id: participant.id)

        result = team.add_member(participant)
        next if result[:success]

        raise StandardError, result[:error]
      end
    end

    def find_or_build_import_team(row_hash, defaults)
      assignment_id = defaults[:assignment_id] || import_export_assignment_id
      raise StandardError, 'assignment_id is required for team import' if assignment_id.blank?

      name = row_hash['name'].presence
      raise StandardError, 'name is required for team import' if name.blank?

      find_or_initialize_by(name: name, type: 'AssignmentTeam', parent_id: assignment_id)
    end

    def find_import_participant(team, participant_id)
      participant_class = participant_class_for(team.type)
      participant_class.find_by(id: participant_id, parent_id: team.parent_id)
    end

    def participant_class_for(team_type)
      %w[AssignmentTeam MentoredTeam].include?(team_type) ? AssignmentParticipant : CourseParticipant
    end

    def participant_field_names
      (1..participant_column_count).map { |index| "#{TEAM_PARTICIPANT_COLUMN_PREFIX}#{index}" }
    end

    def participant_column_count
      assignment = Assignment.find_by(id: import_export_assignment_id) if import_export_assignment_id.present?
      return DEFAULT_TEAM_IMPORT_EXPORT_PARTICIPANT_COLUMNS unless assignment
      return assignment.max_team_size if assignment.max_team_size.present?
      return assignment.participants.count if assignment.participants.count.positive?

      DEFAULT_TEAM_IMPORT_EXPORT_PARTICIPANT_COLUMNS
    end

    def participant_ids_from_row(row_hash)
      row_hash
        .slice(*participant_field_names)
        .values
        .map(&:presence)
        .compact
    end

    def export_scope
      scope = where(type: %w[AssignmentTeam MentoredTeam])
      import_export_assignment_id.present? ? scope.where(parent_id: import_export_assignment_id) : scope
    end

    def import_export_assignment_id
      Thread.current[:team_import_export_assignment_id]
    end

    def import_export_assignment_id=(assignment_id)
      Thread.current[:team_import_export_assignment_id] = assignment_id.presence&.to_i
    end
  end
end
