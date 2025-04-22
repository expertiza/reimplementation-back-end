class CourseTeam < Team
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'

  # Overrides the `assignment_id` method to return `nil`
  # - CourseTeams are not associated with assignments
  def assignment_id
    nil
  end

  # Copies all participants from this CourseTeam to another CourseTeam
  # - Also creates corresponding TeamUserNode entries for team graph linkage
  def copy_members(new_team)
    members = TeamsParticipant.where(team_id: id)
    members.each do |member|
      # Copy the same participant into the new team
      t_participant = TeamsParticipant.create!(team_id: new_team.id, participant: member.participant)
      parent = Course.find(parent_id)
      TeamUserNode.create!(parent_id: parent.id, node_object_id: t_participant.id)
    end
  end

  # Copies this CourseTeam into a new AssignmentTeam or MentoredTeam
  # - Type is determined based on whether the assignment has auto-mentor enabled
  def copy_to_assignment(assignment_id)
    assignment = Assignment.find_by(id: assignment_id)
    new_team = (assignment.auto_assign_mentor ? MentoredTeam : AssignmentTeam).create_team_and_node(assignment_id)

    new_team.update(name: name)
    copy_members(new_team)
  end

  # Factory Method that returns the participant model class for course-based teams
  # - Used to dynamically select correct participant type
  def participant_class
    CourseParticipant
  end

  # Retrieves all participants associated with this course team
  # - Overrides default if needed for clarity or encapsulation
  def participants
    TeamsParticipant.where(team_id: id).map(&:participant)
  end

  # Imports a CourseTeam from a CSV row into the specified course
  # - Raises an error if the course is not found
  def self.import(row, course_id, options)
    raise ImportError, "The course with the id \"#{course_id}\" was not found. <a href='/courses/new'>Create</a> this course?" if Course.find(course_id).nil?

    Team.import(row, course_id, options, CourseTeam)
  end

  # Exports all CourseTeams for a given course into a CSV format
  # - Delegates core export logic to the Team class
  def self.export(csv, parent_id, options)
    Team.export(csv, parent_id, options, CourseTeam)
  end

  # Defines the column headers to be used when exporting CourseTeams
  # - Headers vary based on export options (e.g., include members or not)
  def self.export_fields(options)
    fields = []
    fields.push('Team Name')
    fields.push('Team members') if options[:team_name] == 'false'
    fields.push('Course Name')
  end
end
