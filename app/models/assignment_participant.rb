# frozen_string_literal: true

class AssignmentParticipant < Participant
  include ReviewAggregator
  has_many :sent_invitations, class_name: 'Invitation', foreign_key: 'participant_id'
  belongs_to :user
  validates :handle, presence: true

  def retract_sent_invitations
    sent_invitations.each(&:retract_invitation)
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

  def aggregate_teammate_review_grade(teammate_review_mappings)
    compute_average_review_score(teammate_review_mappings)
  end
end