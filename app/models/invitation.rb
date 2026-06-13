# frozen_string_literal: true

class Invitation < ApplicationRecord
  attr_accessor :skip_validate_invitee_check # need to skip `validate invitee already part of team` check when retracting invitations

  belongs_to :to_participant, class_name: 'AssignmentParticipant', foreign_key: 'to_id', inverse_of: false
  belongs_to :from_participant, class_name: 'AssignmentParticipant', foreign_key: 'from_id'
  # belongs_to :from_team, class_name: 'AssignmentTeam', foreign_key: 'from_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'

  validates_with InvitationValidator

  # Return a new invitation
  # params = :assignment_id, :to_id, :from_id, :reply_status
  def self.invitation_factory(params)
    params[:reply_status] ||= InvitationValidator::WAITING_STATUS
    Invitation.new(params)
  end

  # check if the participant is invited
  def self.invited?(from_id, to_id, assignment_id, reply_status = InvitationValidator::WAITING_STATUS)
    conditions = {
      to_id:,
      from_id:,
      assignment_id:,
      reply_status:
    }
    Invitation.where(conditions).exists?
  end

  # send invite email
  def send_invite_email
    InvitationMailer.with(invitation: self)
                    .send_invitation_email
                    .deliver_later
  end

  # This method handles all that needs to be done upon a user accepting an invitation.
  def accept
    inviter_team = from_participant.team
    invitee_team = to_participant.team

    error_message = nil
    accepted = false

    ActiveRecord::Base.transaction do
      inviter_team.with_lock do
        # 0. Capacity check (race-safe)
        if inviter_team.full?
          error_message = 'Team is full.'
          raise ActiveRecord::Rollback
        end

        # If participant is member of an existing team, update topics and move them between teams.
        if invitee_team.present? && invitee_team.id != inviter_team.id
          inviter_signed_up_team = SignedUpTeam.find_by(team_id: inviter_team.id)
          invitee_signed_up_team = SignedUpTeam.find_by(team_id: invitee_team.id)

          SignedUpTeam.update_topic_after_invite_accept(inviter_signed_up_team, invitee_signed_up_team)

          # Remove from old team first so participant_id uniqueness does not block the move.
          invitee_team.remove_member(to_participant)
        end

        # Add the invitee to the inviter's team and verify success.
        add_result = inviter_team.add_member(to_participant)
        unless add_result[:success]
          error_message = add_result[:error].presence || 'Unable to add participant to team.'
          raise ActiveRecord::Rollback
        end

        update!(reply_status: InvitationValidator::ACCEPT_STATUS)
        accepted = true
      end
    end

    return { success: false, error: (error_message || 'Invitation acceptance failed.') } unless accepted

    { success: true, message: 'Invitation accepted successfully.' }
  rescue StandardError => e
    { success: false, error: "Unexpected error: #{e.message}" }
  end

  # This method handles all that needs to be done upon an user declining an invitation.
  def decline
    update(reply_status: InvitationValidator::DECLINED_STATUS)
  end

  # This method handles all that need to be done upon an invitation retraction.
  def retract
    # Reason: whenever a participant accepts an invitation and becomes part of the inviter team, there might be some invitations sent to the any of the newly joined team members
    # So, in order to retract those invitations, the invitee check needs to be skipped in order to not raise any errors.
    self.skip_validate_invitee_check = true
    update(reply_status: InvitationValidator::RETRACT_STATUS)
  end

  # This will override the default as_json method in the ApplicationRecord class and specify
  def as_json(options = {})
    super(options.merge({
                          only: %i[id reply_status created_at updated_at],
                          include: {
                            assignment: { only: %i[id name] },
                            from_participant: {
                              only: %i[id],
                              include: {
                                user: { only: %i[id name full_name email] },
                                team: { only: %i[id name] }
                              }
                            },
                            # from_team: { only: %i[id name] },
                            to_participant: {
                              only: [:id],
                              include: {
                                user: { only: %i[id name full_name email] }
                              }
                            }
                          }
                        })).tap do |hash|
    end
  end
end

