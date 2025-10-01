class InvitationSentMailer < ApplicationMailer
  default from: 'from@example.com'
  def send_invitation_email
    @invitation = params[:invitation]
    @to_participant = Participant.find(@invitation.to_id)
    @from_participant = Participant.find(@invitation.from_id)
    mail(to: @to_participant.email, subject: 'You have a new invitation from Expertiza')
  end
end
