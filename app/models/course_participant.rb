class CourseParticipant < Participant
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'
  attribute :parent_id, :integer  # Add this line to define the attribute

  # Refactored: Simplified method using 'find_or_create_by'.
  # Copy this participant to an assignment
  # Copy this participant to an assignment
  def copy(assignment_id)
    raise ArgumentError, 'Assignment ID cannot be nil' if assignment_id.nil?

    assignment = Assignment.find_by(id: assignment_id)
    raise ActiveRecord::RecordNotFound, "Assignment with id #{assignment_id} not found" if assignment.nil?

    assignment_participant = AssignmentParticipant.find_or_create_by(user_id: user_id, parent_id: assignment_id)
    assignment_participant.set_handle if assignment_participant.respond_to?(:handle)
    assignment_participant
  end



  # Refactored: Simplified method using 'find_or_create_by'.
  # Provide import functionality for Course Participants
  def self.import(row_hash, _row_header = nil, session, id)
    raise ArgumentError, 'No user id has been specified.' if row_hash.empty?

    user = User.find_by(name: row_hash[:name])
    if user.nil?
      raise ArgumentError, "The record containing #{row_hash[:name]} does not have enough items." if row_hash.length < 4

      attributes = ImportFileHelper.define_attributes(row_hash)
      user = ImportFileHelper.create_new_user(attributes, session)
    end
    course = Course.find(id)
    raise ArgumentError, 'The course with the id "' + id.to_s + '" was not found.' if course.nil?

    unless CourseParticipant.exists?(user_id: user.id, parent_id: id)
      CourseParticipant.create(user_id: user.id, parent_id: id)
    end
  end

  def path
    # Refactored: Use safe navigation to avoid nil errors.
    # Find the course by its parent_id.
    course = Course.find_by(id: parent_id)
    # Construct the path by appending the directory_num to the course's path.
    course&.path.to_s + directory_num.to_s + '/'
  end
end