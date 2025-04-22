class AssignmentTeam < Team
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment

  # Validates that an assignment is associated
  validates :assignment, presence: true
  
  # Custom validation to ensure the team type is either AssignmentTeam or MentoredTeam
  validate :type_must_be_assignment_or_mentored_team

  def copy_to_course_team(course)
    course_team = CourseTeam.new(
      name: "#{name} (Course)",
      max_team_size: max_team_size,
      course: course
    )
    if course_team.save
      team_members.each do |member|
        course_team.add_member(member.user)
      end
    end
    course_team
  end

  protected

  def validate_membership(user)
    # Ensure user is enrolled in the assignment by checking AssignmentParticipant
    assignment.participants.exists?(user: user)
  end

  private

  def type_must_be_assignment_or_mentored_team
    errors.add(:type, 'must be AssignmentTeam or MentoredTeam') unless %w[AssignmentTeam MentoredTeam].include?(type)
  end
end 