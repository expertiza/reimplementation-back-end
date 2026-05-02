# frozen_string_literal: true

class Team < ApplicationRecord

  # Core associations
  has_many :signed_up_teams, dependent: :destroy
  has_many :project_topics, through: :signed_up_teams
  has_many :teams_users, dependent: :destroy
  has_many :teams_participants, dependent: :destroy
  has_many :users, through: :teams_participants
  has_many :participants, through: :teams_participants
  has_many :join_team_requests, dependent: :destroy

  # The team is either an AssignmentTeam or a CourseTeam
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true
  belongs_to :user, optional: true # Team creator

  attr_accessor :max_participants
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentTeam CourseTeam MentoredTeam], message: "must be 'Assignment' or 'Course' or 'Mentor'" }

  after_update :release_topics_if_empty

  # Factory method that creates the appropriate subclass of Team for the given
  # participant and enrolls that participant as a member.
  #
  # - AssignmentParticipant  => AssignmentTeam (parent = assignment)
  # - CourseParticipant      => CourseTeam     (parent = course)
  #
  # This is the mechanism used to back individual submitters (including the
  # phantom "calibration submitters" that an instructor adds on the Calibration
  # tab). Expertiza routes every submission through a team, so even a single
  # submitter needs a team behind the scenes.
  #
  # Params:
  #   participant - an AssignmentParticipant or CourseParticipant
  #   name:       - optional team name; if omitted a stable unique name is
  #                 generated from the user's handle/name.
  #
  # Returns the newly-created team (AssignmentTeam or CourseTeam).
  # Raises ArgumentError if the participant type is not supported.
  def self.create_team_for_participant(participant, name: nil)
    raise ArgumentError, 'participant is required' if participant.nil?

    team_class, parent =
      case participant
      when AssignmentParticipant
        [AssignmentTeam, participant.assignment]
      when CourseParticipant
        [CourseTeam, participant.course]
      else
        raise ArgumentError, "Unsupported participant type: #{participant.class}"
      end

    team_name = name.presence || generate_team_name_for(participant, parent)

    team = team_class.create!(parent_id: parent.id, name: team_name)
    result = team.add_member(participant)

    unless result.is_a?(Hash) && result[:success]
      team.destroy
      error = result.is_a?(Hash) ? result[:error] : 'Unable to add participant to new team'
      raise ActiveRecord::RecordInvalid.new(team), error
    end

    team
  end

  def self.generate_team_name_for(participant, parent)
    base = (participant.user&.handle.presence || participant.user&.name.presence || "participant_#{participant.id}").to_s
    candidate = "#{base}_team"
    return candidate unless Team.exists?(parent_id: parent.id, name: candidate)

    "#{candidate}_#{SecureRandom.hex(3)}"
  end

  def has_member?(user)
    participants.exists?(user_id: user.id)
  end
  
  # Returns the current number of team members
  def team_size
    users.count
  end
  
  # Returns the maximum allowed team size
  def max_size
    if is_a?(AssignmentTeam) && assignment&.max_team_size
      assignment.max_team_size
    elsif is_a?(CourseTeam) && course&.max_team_size
      course.max_team_size
    else
      nil
    end
  end
  
  def full?
    current_size = participants.count

    # assignment teams use the column max_team_size
    if is_a?(AssignmentTeam) && assignment&.max_team_size
      return current_size >= assignment.max_team_size
    end

    # course teams never fill up by default
    false
  end

  # Checks if the given participant is already on any team for the associated assignment or course.
  def participant_on_team?(participant)
    # pick the correct “scope” (assignment or course) based on this team’s class
    scope =
      if is_a?(AssignmentTeam)
        assignment
      elsif is_a?(CourseTeam)
        course
      end

    return false unless scope

    # “scope.teams” includes this team itself plus any sibling teams;
    # check whether any of those teams already has this participant
    scope.teams.any? { |team| team.participants.include?(participant) }
  end

  # Adds participant in the team
  def add_member(participant_or_user)
    participant =
      if participant_or_user.is_a?(AssignmentParticipant) || participant_or_user.is_a?(CourseParticipant)
        participant_or_user
      elsif participant_or_user.is_a?(User)
        participant_type = is_a?(AssignmentTeam) ? AssignmentParticipant : CourseParticipant
        participant_type.find_by(user_id: participant_or_user.id, parent_id: parent_id)
      else
        nil
      end

    # If participant wasn't found or built correctly
    return { success: false, error: "#{participant_or_user.name} is not a participant in this #{is_a?(AssignmentTeam) ? 'assignment' : 'course'}" } if participant.nil?

    return { success: false, error: "Participant already on the team" } if participants.exists?(id: participant.id)
    return { success: false, error: "Unable to add participant: team is at full capacity." } if full?

    team_participant = TeamsParticipant.create(
      participant_id: participant.id,
      team_id: id,
      user_id: participant.user_id
    )

    if team_participant.persisted?
      { success: true }
    else
      { success: false, error: team_participant.errors.full_messages.join(', ') }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  # Removes a participant from this team.
  # - Delete the TeamsParticipant join record
  # - if the participant sent any invitations while being on the team, they all need to be retracted
  # - If the team has no remaining members, destroy the team itself
  def remove_member(participant)
    # retract all the invitations the participant sent (if any) while being on the this team
    participant.retract_sent_invitations

    # Remove the join record if it exists
    tp = TeamsParticipant.find_by(team_id: id, participant_id: participant.id)
    tp&.destroy
    
    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # this will remove the reference only if the participant's current team is the same team removing the participant
    if participant.team_id==id
      participant.update!(team_id: nil)
    end

    # If no participants remain after removal, delete the team
    destroy if participants.empty?
  end

  # Determines whether a given participant is eligible to join the team.
  def can_participant_join_team?(participant)
    # figure out whether we’re in an Assignment or a Course context
    scope, participant_type, label =
      if is_a?(AssignmentTeam)
        [assignment, AssignmentParticipant, "assignment"]
      elsif is_a?(CourseTeam)
        [course, CourseParticipant, "course"]
      else
        return { success: false, error: "Team must belong to Assignment or Course" }
      end

    # Check if the user is already part of any team for this assignment or course
    if participant_on_team?(participant)
      return { success: false, error: "This user is already assigned to a team for this #{label}" }
    end

    # Check if the user is a registered participant for this assignment or course
    registered = participant_type.find_by(
      user_id: participant.user_id,
      parent_id: scope.id
    )

    unless registered
      return { success: false, error: "#{participant.user.name} is not a participant in this #{label}" }
    end

    # All checks passed; participant is eligible to join the team
    { success: true }

  end

  private

  def release_topics_if_empty
    return unless participants.empty?
    project_topics.each { |topic| topic.drop_team(self) }
  end
end
