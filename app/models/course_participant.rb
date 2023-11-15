class CourseParticipant < Participant
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'
  attribute :parent_id, :integer  # Add this line to define the attribute

  # Refactored: Simplified method using 'find_or_create_by'.
  # Copy this participant to an assignment
  def copy(assignment_id)
    part = AssignmentParticipant.find_or_create_by(user_id: user_id, parent_id: assignment_id)
    part.set_handle # Set the handle for the newly created assignment participant.
    part
  end

  # Refactored: Simplified method using 'find_or_create_by'.
  # Provide import functionality for Course Participants
  def self.import(row_hash, _row_header = nil, session, id)
    # Check if a user id has been provided in the row_hash.
    raise ArgumentError, 'No user id has been specified.' if row_hash.empty?

    # Find or create a user with the given name from the row_hash.
    user = User.find_or create_by(name: row_hash[:name])

    # Find the course by its id.
    course = Course.find_by(id: id)
    raise ImportError, 'The course with the id "' + id.to_s + '" was not found.' if course.nil?

    # Find or create a course participant for the user and course.
    CourseParticipant.find_or_create_by(user_id: user.id, parent_id: id)
  end

  def path
    # Refactored: Use safe navigation to avoid nil errors.
    # Find the course by its parent_id.
    course = Course.find_by(id: parent_id)
    # Construct the path by appending the directory_num to the course's path.
    course&.path.to_s + directory_num.to_s + '/'
  end
end