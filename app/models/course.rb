class Course < ApplicationRecord
  enum locale: Locale.code_name_to_db_encoding

  # Associations
  has_many :ta_mappings, dependent: :destroy
  has_many :tas, through: :ta_mappings
  has_many :assignments, dependent: :destroy
  belongs_to :instructor, class_name: 'User', foreign_key: 'instructor_id'
  belongs_to :institution, foreign_key: 'institutions_id'
  has_many :participants, class_name: 'CourseParticipant', foreign_key: 'parent_id', dependent: :destroy
  has_many :course_teams, foreign_key: 'parent_id', dependent: :destroy
  has_one :course_node, foreign_key: 'node_object_id', dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_paper_trail

  # Validations
  validates :name, presence: true
  validates :directory_path, presence: true

  # Return teams associated with this course
  def get_teams
    course_teams
  end

  # Get all participants in this course
  def get_participants
    participants
  end

  # Get a specific participant by user ID
  def get_participant(user_id)
    participants.find_by(user_id: user_id)
  end

  # Check if a user is on any team in the course
  def user_on_team?(user)
    course_teams.joins(:users).exists?(users: { id: user.id })
  end

  # Add a user as a participant to this course
  def add_participant(user_name)
    user = User.find_by(name: user_name)
    raise "No user account exists with the name #{user_name}. Please create the user first." unless user

    participant = participants.find_by(user_id: user.id)
    if participant
      raise "The user #{user.name} is already a participant."
    else
      participants.create(user_id: user.id, permission_granted: user.master_permission_granted)
    end
  end

  def remove_participants(user_ids)
    user_ids.each do |user_id|
      participant = participants.find_by(user_id: user_id)
      raise "User with ID #{user_id} is not a participant." if participant.nil?

      participant.destroy
    end
  end

  # Add a user to a team
  def add_user_to_team(user, team_id)
    team = course_teams.find_by(id: team_id)
    raise "Team not found in this course." unless team

    if user_on_team?(user)
      raise "The user #{user.name} is already assigned to a team for this course."
    end

    team.add_member(user, id)
  end

  # Copy participants from an assignment to this course
  def copy_participants_from_assignment(assignment_id)
    participants = AssignmentParticipant.where(parent_id: assignment_id)
    errors = []

    participants.each do |participant|
      user = User.find(participant.user_id)
      begin
        add_participant(user.name)
      rescue StandardError => e
        errors << e.message
      end
    end

    raise errors.join('<br/>') unless errors.empty?
  end

  # Returns the path for this course
  def path
    raise 'Path cannot be created. The course must be associated with an instructor.' if instructor_id.nil?

    Rails.root.join('pg_data', FileHelper.clean_path(instructor.name), FileHelper.clean_path(directory_path))
  end

  # Analytics
  require 'analytic/course_analytic'
  include CourseAnalytic
end
