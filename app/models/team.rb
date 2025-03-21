class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :project_topics, through: :signed_up_teams
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants
  belongs_to :assignment
  attr_accessor :max_participants
  after_update :release_topics_if_empty


  # TODO Team implementing Teams controller and model should implement this method better.
  # TODO partial implementation here just for the functionality needed for join_team_tequests controller
  def full?
    max_participants ||= 3
    participants.count >= max_participants
  end

  private

  def release_topics_if_empty
    return unless saved_change_to_participants_count? && participants.empty?

    project_topics.each { |topic| topic.drop_team(self) }
  end
end