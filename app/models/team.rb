class Team < ApplicationRecord
  self.inheritance_column = :type

  # Core associations
  belongs_to :user, optional: true # Team creator
  belongs_to :course
  has_many :team_members, dependent: :destroy
  has_many :users, through: :team_members
  has_many :team_join_requests, dependent: :destroy
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :participants

  # Core validations
  validates :name, presence: true
  validates :type, presence: true, inclusion: { in: %w[CourseTeam AssignmentTeam MentoredTeam] }
  validates :max_team_size, presence: true, numericality: { greater_than: 0 }

  # Core team methods
  def add_member(user)
    return false if full? || users.include?(user)
    return false unless validate_membership(user)
    team_members.create(user: user, role: 'member')
  end

  def remove_member(user)
    team_members.find_by(user: user)&.destroy
  end

  def full?
    team_members.count >= max_team_size
  end

  def empty?
    team_members.empty?
  end

  def member?(user)
    users.include?(user)
  end

  def team_size
    team_members.count
  end

  protected

  def validate_membership(user)
    # To be overridden by subclasses
    true
  end
end