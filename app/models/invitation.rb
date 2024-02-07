class Invitation < ApplicationRecord
  after_initialize :set_defaults

  belongs_to :to_user, class_name: 'User', foreign_key: 'to_id', inverse_of: false
  belongs_to :from_user, class_name: 'User', foreign_key: 'from_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'

  validates_with InvitationValidator

  # Return a new invitation
  # params = :assignment_id, :to_id, :from_id, :reply_status
  def self.invitation_factory(params)
    Invitation.new(params)
  end

  # check if the user is invited
  def self.invited?(from_id, to_id, assignment_id)
    conditions = {
      to_id:,
      from_id:,
      assignment_id:,
      reply_status: InvitationValidator::WAITING_STATUS
    }
    @invitations_exist = Invitation.where(conditions).exists?
  end

  # send invite email
  def send_invite_email
    InvitationSentMailer.with(invitation: self)
                        .send_invitation_email
                        .deliver_later
  end

  # After a users accepts an invite, the teams_users table needs to be updated.
  # NOTE: Depends on TeamUser model, which is not implemented yet.
  def update_users_topic_after_invite_accept(_inviter_user_id, _invited_user_id, _assignment_id); end

  # This method handles all that needs to be done upon a user accepting an invitation.
  # Expected functionality: First the users previous team is deleted if they were the only member of that
  # team and topics that the old team signed up for will be deleted.
  # Then invites the user that accepted the invite sent will be removed.
  # Lastly the users team entry will be added to the TeamsUser table and their assigned topic is updated.
  # NOTE: For now this method simply updates the invitation's reply_status.
  def accept_invitation(_logged_in_user)
    update(reply_status: InvitationValidator::ACCEPT_STATUS)
  end

  # This method handles all that needs to be done upon an user declining an invitation.
  def decline_invitation(_logged_in_user)
    update(reply_status: InvitationValidator::REJECT_STATUS)
  end

  # This method handles all that need to be done upon an invitation retraction.
  def retract_invitation(_logged_in_user)
    destroy
  end

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

  def set_defaults
    self.reply_status ||= InvitationValidator::WAITING_STATUS
  end
end
