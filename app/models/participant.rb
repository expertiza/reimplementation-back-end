# frozen_string_literal: true

class Participant < ApplicationRecord
  # Legacy databases (and branch code paths, e.g. StudentTask) read
  # participants.OK_to_show; the merged schema uses :permission_granted.
  alias_attribute :OK_to_show, :permission_granted

  # Associations
  belongs_to :user
  has_many   :join_team_requests, dependent: :destroy
  # belongs_to :team, optional: true
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true, inverse_of: :participants
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true, inverse_of: :participants

  # Validations
  validates :user_id, presence: true
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentParticipant CourseParticipant], message: "must be either 'AssignmentParticipant' or 'CourseParticipant'" }

  def retract_sent_invitations
    # do nothing. Invitations are only sent by AssignmentParticipants only.
  end

  # Methods
  def fullname
    user.name
  end

  # The branch-side SubmittedContentController records submissions as
  # `submitted_by: @participant.user_name`; expose the username the same way
  # the legacy AssignmentParticipant did.
  def user_name
    user&.username
  end

  def team
    TeamsParticipant.where(participant: self).first&.team
  end

end