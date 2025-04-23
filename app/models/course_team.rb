class CourseTeam < Team
  #Each course team must belong to a course
  belongs_to :course

  # Validates that the course is present
  validates :course, presence: true

  #Custom validation to ensure the team type CourseTeam
  validate :type_must_be_course_team


  #adds members to the course team post validation
  def add_member(user)
    return false unless validate_membership(user)
    super(user)
  end

  # Copies the current course team to an assignment team
  # - Creates a new AssignmentTeam with a modified name
  # - Copies team members from the assignment team to the course team
  def copy_to_assignment_team(assignment)
    assignment_team = AssignmentTeam.new(
      name: "#{name} (Assignment)",             # Appends "(Assignment)" to the team name
      max_team_size: max_team_size,             # Preserves original max team size
      assignment: assignment                    # Associates the course team with an assignment
    )
    if assignment_team.save
      team_members.each do |member|
        assignment_team.add_member(member.user) # Copies each member to the new assignment team
      end
    end
    assignment_team       # Returns the newly created assignment team object
  end

  protected

  def validate_membership(user)
    # Check if user is enrolled in any assignment in the course
    course.assignments.any? { |assignment| assignment.participants.exists?(user: user) }
  end

  private

  # Custom validation method for team type
  # - Ensures the type is 'CourseTeam'
  def type_must_be_course_team
    errors.add(:type, 'must be CourseTeam') unless type == 'CourseTeam'
  end
end 