# app/models/signed_up_team.rb
class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team

  def self.find_team_participants(assignment_id, _ip_address = nil)
    SignedUpTeam
      .joins(:sign_up_topic)                                           # join sign_up_topics
      .joins(team: { teams_participants: { participant: :user } })     # nested hash‐style joins
      .where(sign_up_topics: { assignment_id: assignment_id })
      .select(
        'signed_up_teams.id               AS id',
        'signed_up_teams.team_id          AS team_id',
        'sign_up_topics.id                AS topic_id',
        'teams.name                       AS team_name_placeholder',
        'users.name                       AS user_name_placeholder',
        "CONCAT('[', teams.name, '] ', users.name, ' ') AS name",
        'signed_up_teams.is_waitlisted    AS is_waitlisted'
      )
  end
end
