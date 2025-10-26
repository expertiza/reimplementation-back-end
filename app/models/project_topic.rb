class ProjectTopic < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams, through: :signed_up_teams
  belongs_to :assignment

  # Ensures the number of max choosers is non-negative
  validates :max_choosers, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }

  # Ensures topic name is present
  validates :topic_name, presence: true

  # Attempts to sign up a team for this topic.
  # If slots are available, it's confirmed; otherwise, waitlisted.
  # Also removes any previous waitlist entries for the same team on other topics.
  # CHANGED: Renamed from signup_team to sign_team_up for verb-based clarity (E2552)
  def sign_team_up(team)
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

  # Drops a team from this topic and promotes a waitlisted team if necessary.
  def drop_team(team)
    signed_up_team = signed_up_teams.find_by(team: team)
    return unless signed_up_team
    team_confirmed = !signed_up_team.is_waitlisted?
    signed_up_team.destroy!
    promote_waitlisted_team if team_confirmed
  end

  # Returns the number of available slots left for this topic.
  def available_slots
    max_choosers - confirmed_teams_count
  end

  # Checks if there are any open slots for this topic.
  def slot_available?
    available_slots.positive?
  end

  # Returns all SignedUpTeam entries (both confirmed and waitlisted).
  def get_signed_up_teams
    signed_up_teams
  end

  # Returns only confirmed teams associated with this topic.
  def confirmed_teams
    teams.joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: false })
  end

  # Returns only waitlisted teams ordered by signup time (FIFO).
  def waitlisted_teams
    teams.joins(:signed_up_teams)
         .where(signed_up_teams: { is_waitlisted: true })
         .order('signed_up_teams.created_at ASC')
  end

  private

  # Returns the count of teams confirmed for this topic.
  def confirmed_teams_count
    signed_up_teams.confirmed.count
  end

  # Promotes the earliest waitlisted team to confirmed.
  def promote_waitlisted_team
    next_signup = SignedUpTeam.where(project_topic_id: id, is_waitlisted: true).order(:created_at).first
    return unless next_signup

    next_signup.update_column(:is_waitlisted, false)
    remove_from_waitlist(next_signup.team)
  end

  # Removes waitlist entries for the given team from all other topics.
  def remove_from_waitlist(team)
    team.signed_up_teams.waitlisted.where.not(project_topic_id: id).destroy_all
  end
end
