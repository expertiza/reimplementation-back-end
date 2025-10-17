# frozen_string_literal: true

class Invitation < ApplicationRecord
  after_initialize :set_defaults

  belongs_to :to_participant, class_name: 'Participant', foreign_key: 'to_id', inverse_of: false
  belongs_to :from_participant, class_name: 'Participant', foreign_key: 'from_id', inverse_of: false
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
    InvitationMailer.with(invitation: self)
                        .send_invitation_email
                        .deliver_later
  end

  # After a participant accepts an invite, the teams_participant table needs to be updated.
  def update_users_topic_after_invite_accept(_inviter_participant_id, _invited_participant_id, _assignment_id); end

  # This method handles all that needs to be done upon a user accepting an invitation.
  def accept_invitation
    inviter_team = from_team
    invitee_team = to_participant.team

    # Wrap in transaction to prevent partial updates and concurrency
    ActiveRecord::Base.transaction do
      # 1. Add the invitee to the inviter's team
      inviter_team.add_participant(to_participant)
      
      # if participant is member of an existing team then only step 2 and 3 makes sense. otherwise just need to add the participant to the inviter team
      if invitee_team.present?
        # 2. Update the participant’s and team's assigned topic
        inviter_signed_up_team = SignedUpTeam.find_by(team_id: invitee_team.id)
        invitee_signed_up_team = SignedUpTeam.find_by(team_id: inviter_team.id)
  
        SignedUpTeam.update_topic_after_invite_accept(inviter_signed_up_team,invitee_signed_up_team)
  
        # 3. Remove participant from their old team
        invitee_team.remove_participant(to_participant)
      end

      # 4. Mark this invitation as accepted
      update!(reply_status: InvitationValidator::ACCEPT_STATUS)
    end

    { success: true, message: "Invitation accepted successfully." }

  rescue TeamFullError => e
    { success: false, error: e.message }
  rescue => e
    { success: false, error: "Unexpected error: #{e.message}" }
  end


  # This method handles all that needs to be done upon an user declining an invitation.
  def decline_invitation
    update(reply_status: InvitationValidator::REJECT_STATUS)  
  end

  # This method handles all that need to be done upon an invitation retraction.
  def retract_invitation
    destroy!
  end

  # This will override the default as_json method in the ApplicationRecord class and specify
  def as_json(options = {})
    super(options.merge({
                          only: %i[id reply_status created_at updated_at],
                          include: {
                            assignment: { only: %i[id name] },
                            from_team: { only: %i[id name] },
                            to_participant: {    
                              only: [:id],
                              include: {
                                user: { only: %i[id name full_name email] }
                              }}
                          }
                        })).tap do |hash|
    end
  end

  def set_defaults
    self.reply_status ||= InvitationValidator::WAITING_STATUS
  end
end