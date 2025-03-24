class ProjectTopic < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams, through: :signed_up_teams
  belongs_to :assignment
  validates :max_choosers, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 0 
  }
  validates :topic_name, presence: true

  def signup_team(team)
    return false if signed_up_teams.exists?(team: team)
    ActiveRecord::Base.transaction do
      signed_up_team = signed_up_teams.create!(
        team: team,
        is_waitlisted: !slot_available?
      )
      remove_from_waitlist(team) unless signed_up_team.is_waitlisted?
      true
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  def drop_team(team)
    signed_up_team = signed_up_teams.find_by(team: team)
    return unless signed_up_team
    team_confirmed = !signed_up_team.is_waitlisted?
    signed_up_team.destroy!
    promote_waitlisted_team if team_confirmed
  end

  def available_slots
    max_choosers - confirmed_teams_count
  end

  def slot_available?
    available_slots.positive?
  end

  def get_signed_up_teams
    signed_up_teams
  end

  def confirmed_teams
    teams.joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: false })
  end

  def waitlisted_teams
    teams.joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: true })
         .order('signed_up_teams.created_at ASC')
  end

  private

  def confirmed_teams_count
    signed_up_teams.confirmed.count
  end

  def promote_waitlisted_team
    next_team = waitlisted_teams.first
    return unless next_team
    signed_up_teams.find_by(team: next_team)&.update!(is_waitlisted: false)
    remove_from_waitlist(next_team)
  end

  def remove_from_waitlist(team)
    team.signed_up_teams.waitlisted.destroy_all
  end
end