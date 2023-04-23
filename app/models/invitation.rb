class Invitation < ApplicationRecord
  after_initialize :set_defaults

  ACCEPT_STATUS = 'A'.freeze
  REJECT_STATUS = 'R'.freeze
  WAITING_STATUS = 'W'.freeze

  belongs_to :to_user, class_name: 'User', foreign_key: 'to_id', inverse_of: false
  belongs_to :from_user, class_name: 'User', foreign_key: 'from_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'
  validates :reply_status, presence: true, length: { maximum: 1 }
  validates_inclusion_of :reply_status, in: [ACCEPT_STATUS, REJECT_STATUS, WAITING_STATUS], allow_nil: false
  validates :assignment_id, uniqueness: {
    scope: %i[from_id to_id reply_status],
    message: 'You cannot have duplicate invitations'
  }
  validate :to_from_cant_be_same

  # validate if the to_id and from_id are same
  def to_from_cant_be_same
    return unless from_id == to_id

    errors.add(:from_id, 'to and from users should be different')
  end

  # Return a new invitation
  # params = :assignment_id, :to_id, :from_id, :reply_status
  def self.invitation_factory(params)
    Invitation.new(params)
  end

  # check if the user is invited
  def self.invited?(from_id, to_id, assignment_id)
    @invitations_count = Invitation.where(to_id:)
                                   .where(from_id:)
                                   .where(assignment_id:)
                                   .where(reply_status: WAITING_STATUS)
                                   .count
    @invitations_count.positive?
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
    update(reply_status: ACCEPT_STATUS)
  end

  # This method handles all that needs to be done upon an user declining an invitation.
  def decline_invitation(_logged_in_user)
    update(reply_status: REJECT_STATUS)
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
    self.reply_status ||= WAITING_STATUS
  end
end
