# frozen_string_literal: true

class CourseParticipant < Participant
  validates :handle, presence: true

  def parent_context
    course
  end
end
