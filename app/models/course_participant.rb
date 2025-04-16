# frozen_string_literal: true

class CourseParticipant < Participant
  belongs_to :course, class_name: 'Course', foreign_key: 'course_id'
  belongs_to :user
  validates :handle, presence: true

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
