# frozen_string_literal: true

class AssignmentTeam < Team
  include Analytic::AssignmentTeamAnalytic
  include ReviewAggregator
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :review_response_maps, foreign_key: 'reviewee_id'
  has_many :responses, through: :review_response_maps, foreign_key: 'map_id'


  # Copies the current assignment team to a course team
  # - Creates a new CourseTeam with a modified name
  # - Copies team members from the assignment team to the course team
  def copy_to_course_team(course)
    course_team = CourseTeam.new(
      name: "#{name} (Course)",              # Appends "(Course)" to the team name
      max_team_size: max_team_size,         # Preserves original max team size
      course: course                         # Associates new team with the given course
    )
    if course_team.save
      team_members.each do |member|
        course_team.add_member(member.user)  # Copies each member to the new course team
      end
    end
    course_team   # Returns the newly created course team object
  end  
  # Adds a participant to this team.
  # - Update the participant's team_id (so their direct reference is consistent)
  # - Ensure there is a TeamsParticipant join record connecting the participant and this team
  def add_participant(participant)
    # need to have a check if the team is full then it can not add participant to the team
    raise TeamFullError, "Team is full." if full?

    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    participant.update!(team_id: id)

    # Create or reuse the join record to maintain the association
    TeamsParticipant.find_or_create_by!(participant_id: participant.id, team_id: id, user_id: participant.user_id)
  end

  # Removes a participant from this team.
  # - Delete the TeamsParticipant join record
  # - If the team has no remaining members, destroy the team itself
  def remove_participant(participant)
    # Remove the join record if it exists
    tp = TeamsParticipant.find_by(team_id: id, participant_id: participant.id)
    tp&.destroy

    # If no participants remain after removal, delete the team
    destroy if participants.empty?
  end

  # Get the review response map
  def review_map_type
    'ReviewResponseMap'
  end

  def fullname
    name
  end

  # Use current object (AssignmentTeam) as reviewee and create the ReviewResponseMap record
  def assign_reviewer(reviewer)
    assignment = Assignment.find(parent_id)
    raise 'The assignment cannot be found.' if assignment.nil?

    ReviewResponseMap.create(reviewee_id: id, reviewer_id: reviewer.get_reviewer.id, reviewed_object_id: assignment.id, team_reviewing_enabled: assignment.team_reviewing_enabled)
  end

  # Whether the team has submitted work or not
  def has_submissions?
    submitted_files.any? || submitted_hyperlinks.present?
  end

  # Computes the average review grade for an assignment team.
  # This method aggregates scores from all ReviewResponseMaps (i.e., all reviewers of the team).
  def aggregate_review_grade
    compute_average_review_score(review_mappings)
  end
  
  # Adds a participant to this team.
  # - Update the participant's team_id (so their direct reference is consistent)
  # - Ensure there is a TeamsParticipant join record connecting the participant and this team
  def add_participant(participant)
    # need to have a check if the team is full then it can not add participant to the team
    raise TeamFullError, "Team is full." if full?

    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # participant.update!(team_id: id)

    # Create or reuse the join record to maintain the association
    TeamsParticipant.find_or_create_by!(participant_id: participant.id, team_id: id, user_id: participant.user_id)
  end

  # Removes a participant from this team.
  # - Delete the TeamsParticipant join record
  # - if the participant sent any invitations while being on the team, they all need to be retracted
  # - If the team has no remaining members, destroy the team itself
  def remove_participant(participant)
    # retract all the invitations the participant sent (if any) while being on the this team
    participant.retract_sent_invitations

    # Remove the join record if it exists
    tp = TeamsParticipant.find_by(team_id: id, participant_id: participant.id)
    tp&.destroy
    
    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # participant.update!(team_id: nil)

    # If no participants remain after removal, delete the team
    destroy if participants.empty?
  end

  protected

  # Validates if a user is eligible to join the team
  # - Checks whether the user is a participant of the associated assignment
  def validate_membership(user)
    # Ensure user is enrolled in the assignment by checking AssignmentParticipant
    assignment.participants.exists?(user: user)
  end

  private

  # Validates that the team is an AssignmentTeam or a subclass (e.g., MentoredTeam)
  def validate_assignment_team_type
    unless self.kind_of?(AssignmentTeam)
      errors.add(:type, 'must be an AssignmentTeam or its subclass')
    end
  end
end 

class TeamFullError < StandardError; end
