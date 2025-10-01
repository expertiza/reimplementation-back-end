class AssignmentTeam < Team
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'


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
    # Update the participant's team_id column
    participant.update!(team_id: id)

    # Create or reuse the join record to maintain the association
    TeamsParticipant.find_or_create_by!(
      participant_id: participant.id,
      team_id: id
    )
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
