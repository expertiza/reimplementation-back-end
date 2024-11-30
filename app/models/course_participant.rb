class CourseParticipant < Participant
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'

  # Copy this participant to an assignment
  def copy_to_assignment(assignment_id)
    part = AssignmentParticipant.find_or_create_by(user_id: user_id, parent_id: assignment_id)
    part.set_handle if part.persisted?
    part
  end

  # Provide import functionality for Course Participants
  def self.import(row_hash, session, course_id)
    raise ArgumentError, 'No user ID has been specified.' if row_hash.empty?

    user = User.find_by(name: row_hash[:username])
    unless user
      raise ArgumentError, "The record containing #{row_hash[:username]} does not have enough items." if row_hash.length < 4

      attributes = ImportFileHelper.define_attributes(row_hash)
      user = ImportFileHelper.create_new_user(attributes, session)
    end

    course = Course.find(course_id)
    raise ImportError, "The course with the ID #{course_id} was not found." unless course

    unless exists?(user_id: user.id, parent_id: course_id)
      create(user_id: user.id, parent_id: course_id)
    end
  end

  # Generate a path for this participant
  def path
    course.path.join(directory_num.to_s)
  end
end
