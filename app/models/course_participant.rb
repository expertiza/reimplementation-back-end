# frozen_string_literal: true

class CourseParticipant < Participant
  belongs_to :course, class_name: 'Course', foreign_key: 'course_id'
  belongs_to :user
  validates :handle, presence: true

  # Copies a course participant to an assignment participant.
  def copy_to_assignment(assignment_id)
    part = AssignmentParticipant.find_or_initialize_by(
      user_id: user_id,
      assignment_id: assignment_id
    )
    part.set_handle if part.new_record?
    part.save! if part.new_record?
    part
  end

  # Import a CourseParticipant from a CSV row.
  # row_hash     - Hash with symbol keys mapping to CSV columns (must include :username)
  # session      - current session (for creating new users)
  # course_id    - ID of the Course we’re importing into
  #
  # Returns the existing or newly-created CourseParticipant.
  #
  # Raises:
  # - ArgumentError if :username is missing or if the row is too short to create a new user
  # - ImportError   if the course isn’t found
  def self.import(row_hash, _row_header = nil, session:, course_id:)
    username = row_hash[:username]&.strip
    raise ArgumentError, "No username provided." if username.blank?

    user = User.find_by(name: username)
    if user.nil?
      # we expect at least enough columns to build a user
      if row_hash.size < 4
        raise ArgumentError,
              "Row for '#{username}' does not contain enough fields to create a new user."
      end

      attrs = ImportFileHelper.define_attributes(row_hash)
      user  = ImportFileHelper.create_new_user(attrs, session)
    end

    course = Course.find_by(id: course_id)
    raise ImportError, "Course with id #{course_id} not found." unless course

    find_or_create_by!(user_id: user.id, course_id: course.id) do |cp|
      cp.handle = user.name
    end
  end

  # Sets the participant's handle based on the user's handle or name.
  def set_handle
    self.handle = if user.handle.nil? || user.handle.strip.empty?
                    user.name
                    # Check if any Participant record for this course already uses the user's handle.
                  elsif Participant.exists?(course_id: course.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    save
  end
end
