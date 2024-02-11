class InvitationSentMailer < ApplicationMailer
  default from: 'from@example.com'
  def send_invitation_email
    @invitation = params[:invitation]
    @to_user = User.find(@invitation.to_id)
    @from_user = User.find(@invitation.from_id)
    mail(to: @to_user.email, subject: 'You have a new invitation from Expertiza')
  end
end
