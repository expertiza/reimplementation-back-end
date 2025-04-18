# Represents a record of a submission made by a student team
# This model tracks all submission activities 
class SubmissionRecord < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :team, class_name: 'AssignmentTeam'
  belongs_to :assignment

  # Validations
  validates :content, presence: true
  validates :operation, presence: true
  validates :team_id, presence: true
  validates :user, presence: true
  validates :assignment_id, presence: true

  # Scopes for common queries
  scope :recent, -> { order(created_at: :desc) }
  scope :for_team, ->(team_id) { where(team_id: team_id) }
  scope :for_assignment, ->(assignment_id) { where(assignment_id: assignment_id) }
end