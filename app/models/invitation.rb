class Invitation < ApplicationRecord
  ACCEPT_STATUS = 'A'
  REJECT_STATUS = 'R'
  WAITING_STATUS = 'W'
  belongs_to :to_user, class_name: 'User', foreign_key: 'to_id', inverse_of: false
  belongs_to :from_user, class_name: 'User', foreign_key: 'from_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key:   'assignment_id'
  validates :reply_status, presence: true, length: { maximum: 1 }
  validates_inclusion_of :reply_status, in: [ACCEPT_STATUS, REJECT_STATUS, WAITING_STATUS], allow_nil: false
  validates :assignment_id, uniqueness: {
    scope: %i[from_id to_id reply_status],
    message: 'You cannot have duplicate invitations'
  }
  validate :to_from_cant_be_same

  # validate if the to_id and from_id are same
  def to_from_cant_be_same
    if self.from_id == self.to_id
      errors.add(:from_id, 'to and from users should be different')
    end
  end

  # Return a new invitation
  # params = :assignment_id, :to_id, :from_id, :reply_status
  def invitation_factory(params); end

  # send invite email
  def send_invite_email; end

  # Remove all invites sent by a user for an assignment.
  def self.remove_users_sent_invites_for_assignment(user_id, assignment_id); end

  # After a users accepts an invite, the teams_users table needs to be updated.
  # NOTE: Depends on TeamUser model, which is not implemented yet.
  def self.update_users_topic_after_invite_accept(inviter_user_id, invited_user_id, assignment_id); end

  # This method handles all that needs to be done upon a user accepting an invitation.
  # First the users previous team is deleted if they were the only member of that
  # team and topics that the old team signed up for will be deleted.
  # Then invites the user that accepted the invite sent will be removed.
  # Last the users team entry will be added to the TeamsUser table and their assigned topic is updated
  def self.accept_invitation(invitation, logged_in_user)
    invitation.update(reply_status: ACCEPT_STATUS)
  end

  # This method handles all that needs to be done upon an user decline an invitation.
  def self.decline_invitation(invitation, logged_in_user)
    invitation.update(reply_status: REJECT_STATUS)
  end

  # This method handles all that need to be done upon an invitation retraction.
  def self.retract_invitation(invite_id, logged_in_user); end

  # check if the user is invited
  def self.invited?(invitee_user_id, invited_user_id, assignment_id); end

  # This will override the default as_json method in the ApplicationRecord class and specify
  def as_json(options = {})
    super(options.merge({
                          only: %i[id reply_status created_at updated_at],
                          include: {
                            assignment: { only: %i[id name] },
                            from_user: { only: %i[id name fullname email] },
                            to_user: { only: %i[id name fullname email] }
                          }
                        })).tap do |hash|
    end
  end

  def set_defaults; end

end
