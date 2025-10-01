class Invitation < ApplicationRecord
  after_initialize :set_defaults

  belongs_to :to_participant, class_name: 'Participant', foreign_key: 'to_id', inverse_of: false
  belongs_to :from_team, class_name: 'AssignmentTeam', foreign_key: 'from_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'

  validates_with InvitationValidator

  # Return a new invitation
  # params = :assignment_id, :to_id, :from_id, :reply_status
  def self.invitation_factory(params)
    Invitation.new(params)
  end

  # check if the participant is invited
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

  # This method handles all that needs to be done upon a user accepting an invitation.
  def accept_invitation
    inviter_team = from_team                  # Team that sent the invitation
    invitee_team = to_participant.team        # Team of the invited participant

    # 1. Update the participant’s and team's assigned topic
    inviter_signed_up_team = SignedUpTeam.find_by(team_id: invitee_team.id)
    invitee_signed_up_team = SignedUpTeam.find_by(team_id: inviter_team.id)
    SignedUpTeam.update_topic_after_invite_accept(
      inviter_signed_up_team,
      invitee_signed_up_team
    )

    # 2. Remove participant from their old team
    invitee_team.remove_participant(to_participant)

    # 3. Add the invitee to the inviter's team
    inviter_team.add_participant(to_participant)

    # 4. Mark this invitation as accepted
    update!(reply_status: InvitationValidator::ACCEPT_STATUS)
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
                            from_team: { only: %i[id name] },
                            to_participant: { only: %i[id name fullname email] }
                          }
                        })).tap do |hash|
    end
  end

  def set_defaults
    self.reply_status ||= InvitationValidator::WAITING_STATUS
  end
end
