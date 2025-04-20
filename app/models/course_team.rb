class CourseTeam < Team
  belongs_to :course

  validates :course, presence: true
  validate :type_must_be_course_team

  def add_member(user)
    return false unless validate_membership(user)
    super(user)
  end

  def copy_to_assignment_team(assignment)
    assignment_team = AssignmentTeam.new(
      name: "#{name} (Assignment)",
      max_team_size: max_team_size,
      assignment: assignment
    )
    if assignment_team.save
      team_members.each do |member|
        assignment_team.add_member(member.user)
      end
    end
    assignment_team
  end

  protected

  def validate_membership(user)
    # Check if user is enrolled in any assignment in the course
    course.assignments.any? { |assignment| assignment.participants.exists?(user: user) }
  end

  private

  def type_must_be_course_team
    errors.add(:type, 'must be CourseTeam') unless type == 'CourseTeam'
  end
end 