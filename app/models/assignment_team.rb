class AssignmentTeam < Team
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment

  # Validates that an assignment is associated
  validates :assignment, presence: true
  
  # Custom validation to ensure the team type is either AssignmentTeam or MentoredTeam
  validate :type_must_be_assignment_or_mentored_team


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

  protected

    # Validates if a user is eligible to join the team
  # - Checks whether the user is a participant of the associated assignment
  def validate_membership(user)
    # Ensure user is enrolled in the assignment by checking AssignmentParticipant
    assignment.participants.exists?(user: user)
  end

  private

  
  # Custom validation method for team type
  # - Ensures the type is either 'AssignmentTeam' or 'MentoredTeam'
  def type_must_be_assignment_or_mentored_team
    errors.add(:type, 'must be AssignmentTeam or MentoredTeam') unless %w[AssignmentTeam MentoredTeam].include?(type)
  end
end 