class InvitationMailer < ApplicationMailer
  default from: 'from@example.com'
  
  def send_invitation_email
    @invitation = params[:invitation]
    @to_participant = Participant.find(@invitation.to_id)
    @from_team = AssignmentTeam.find(@invitation.from_id)
    mail(to: @to_participant.user.email, subject: 'You have a new invitation from Expertiza')
  end

  # Send acceptance email to the invitee
  def send_acceptance_email
    @invitation = params[:invitation]
    @invitee = Participant.find(@invitation.to_id)
    @inviter_team = AssignmentTeam.find(@invitation.from_id)
    @assignment = Assignment.find(@invitation.assignment_id)
    mail(to: @invitee.user.email, subject: 'Your invitation has been accepted')
  end

  # Send acceptance notification to the entire inviting team
  def send_team_acceptance_notification
    @invitation = params[:invitation]
    @invitee = Participant.find(@invitation.to_id)
    @inviter_team = AssignmentTeam.find(@invitation.from_id)
    @assignment = Assignment.find(@invitation.assignment_id)
    
    # Get all team members' emails
    team_member_emails = @inviter_team.participants.map { |p| p.user.email }
    
    mail(to: team_member_emails, subject: "#{@invitee.user.full_name} has accepted the team invitation")
  end
end