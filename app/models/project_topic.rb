class ProjectTopic < ApplicationRecord
  # Associations
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams, through: :signed_up_teams 
  belongs_to :assignment

  # Validations
  validates :max_choosers, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 0 
  }
  validates :topic_name, presence: true

  # Sign up a team to the topic with waitlist management
  def signup_team(team)
    return false if signed_up_teams.exists?(team: team)

    ActiveRecord::Base.transaction do
      signed_up_team = signed_up_teams.create!(
        team: team,
        is_waitlisted: !slot_available?
      )

      # Remove from other waitlists if successfully registered
      remove_from_other_waitlists(team) unless signed_up_team.is_waitlisted?
      true
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  # Remove team from topic and handle waitlist promotion
  def drop_team(team)
    signed_up_team = signed_up_teams.find_by(team: team)
    return unless signed_up_team

    was_confirmed = !signed_up_team.is_waitlisted?
    signed_up_team.destroy!

    promote_waitlisted_team if was_confirmed
  end

  # Get current number of available slots
  def available_slots
    max_choosers - confirmed_teams_count
  end

  # Check if slot is available
  def slot_available?
    available_slots.positive?
  end

  # Get confirmed teams
  def confirmed_teams
    teams.joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: false })
  end

  # Get waitlisted teams in order
  def waitlisted_teams
    teams.joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: true })
         .order('signed_up_teams.created_at ASC')
  end

  private

  def confirmed_teams_count
    signed_up_teams.where(is_waitlisted: false).count
  end

  def promote_waitlisted_team
    next_team = waitlisted_teams.first
    return unless next_team

    signed_up_teams.find_by(team: next_team)&.update!(is_waitlisted: false)
    remove_from_other_waitlists(next_team)
  end

  def remove_from_other_waitlists(team)
    team.signed_up_teams.waitlisted.destroy_all
  end
end
