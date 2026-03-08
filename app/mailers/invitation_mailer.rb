class InvitationMailer < ApplicationMailer
  default from: 'from@example.com'
  def send_invitation_email
    puts @invitation.inspect
    @invitation = params[:invitation]
    @to_participant = Participant.find(@invitation.to_id)
    @from_participant = Participant.find(@invitation.from_id)
    @from_team = AssignmentTeam.find_by(id: @from_participant.team_id)
    @assignment = Assignment.find(@invitation.assignment_id)
    mail(to: @to_participant.user.email, subject: 'You have a new invitation from Expertiza for assignment ' + @assignment.name + ' by team ' + @from_team.name)
  end
end