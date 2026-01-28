class JoinTeamRequestMailer < ApplicationMailer
  default from: 'from@example.com'

  # Send acceptance email to the person whose join request was accepted
  def send_acceptance_email
    @join_team_request = params[:join_team_request]
    @participant = @join_team_request.participant
    @team = @join_team_request.team
    @assignment = @team.assignment
    mail(to: @participant.user.email, subject: 'Your join team request has been accepted')
  end
end
