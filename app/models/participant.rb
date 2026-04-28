# frozen_string_literal: true

class Participant < ApplicationRecord
  belongs_to :user
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true, inverse_of: :participants
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true, inverse_of: :participants
  belongs_to :duty, optional: true

  validates :user_id, presence: true
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentParticipant CourseParticipant], message: "must be either 'AssignmentParticipant' or 'CourseParticipant'" }
  validate :duty_limit_within_team, if: -> { duty_id.present? && team.present? }

  def retract_sent_invitations
  end

  def fullname
    user.full_name
  end

  def team
    TeamsParticipant.where(participant: self).first&.team
  end

  private

  def duty_limit_within_team
    assignment_duty = AssignmentsDuty.find_by(assignment_id: parent_id, duty_id: duty_id)
    limit = assignment_duty&.max_members_for_duty || 1

    count = TeamsParticipant.where(team_id: team.id)
                            .joins("INNER JOIN participants ON teams_participants.participant_id = participants.id")
                            .where(participants: { duty_id: duty_id })
                            .where.not(participants: { id: id })
                            .count

    if count >= limit
      errors.add(:duty, "limit reached for this team. Only #{limit} member(s) can be a #{duty.name}.")
    end
  end
end