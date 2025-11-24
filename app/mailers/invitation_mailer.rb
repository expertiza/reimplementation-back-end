class InvitationMailer < ApplicationMailer
  default from: 'from@example.com'
  def send_invitation_email
    @invitation = params[:invitation]
    @to_participant = Participant.find(@invitation.to_id)
    @from_team = AssignmentTeam.find(@invitation.from_id)
    mail(to: @to_participant.user.email, subject: 'You have a new invitation from Expertiza')
  end
end