class CourseParticipant < Participant
  belongs_to :user
  validates :handle, presence: true

  def set_handle
    # normalize the user’s preferred handle
    desired = user.handle.to_s.strip

    self.handle =
      if desired.empty?
        # no handle on the user, fall back to their name
        user.name
      elsif CourseParticipant.exists?(parent_id: course.id, handle: desired)
        # someone else in this course already has that handle
        user.name
      else
        # it’s unique, so use it
        desired
      end

    save
  end
end
