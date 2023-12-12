class CourseParticipant < Participant
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'
  attribute :parent_id, :integer
  attribute :directory_num, :integer

  # Copy this participant to an assignment
  # Parameter : assignment ID
  # Returns : Assignment Participant
  def copy(assignment_id)
    raise ArgumentError, 'Assignment ID cannot be nil' if assignment_id.nil?

    assignment = Assignment.find_by(id: assignment_id)
    raise ActiveRecord::RecordNotFound, "Assignment with id #{assignment_id} not found" if assignment.nil?

    assignment_participant = AssignmentParticipant.find_or_create_by(user_id: user_id, parent_id: assignment_id)
    assignment_participant.set_handle if assignment_participant.respond_to?(:handle)
    assignment_participant
  end

  # Provides import functionality for Course Participants
  # If user does not exist, it will be created and added to this assignment
  # Parameters : Row hash, session, CourseID
  def self.import(row_hash, _row_header = nil, session, course_id)
    raise ArgumentError, 'No user id has been specified.' if row_hash.empty?

    user = User.find_by(name: row_hash[:name])
    if user.nil?
      raise ArgumentError, "The record containing #{row_hash[:name]} does not have enough items." if row_hash.length < 4

      attributes = ImportFileHelper.define_attributes(row_hash)
      user = ImportFileHelper.create_new_user(attributes, session)
    end
    course = Course.find(course_id)
    raise ArgumentError, 'The course with the id "' + course_id.to_s + '" was not found.' if course.nil?

    unless CourseParticipant.exists?(user_id: user.id, parent_id: course_id)
      CourseParticipant.create(user_id: user.id, parent_id: course_id)
    end
  end

  # Provides path based on current course participant instance
  def path
    Course.find(parent_id).path + directory_num.to_s + '/'
  end

end