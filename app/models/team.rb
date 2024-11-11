class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants
  belongs_to :assignment
  attr_accessor :max_participants

  # TODO Team implementing Teams controller and model should implement this method better.
  # TODO partial implementation here just for the functionality needed for join_team_tequests controller
  def full?

    max_participants ||= 3
    if participants.count >= max_participants
      true
    else
      false
    end
  end
end
