class Instructor < User

  # Get all users whose parent is the instructor
  def managed_users
    User.where(parent_id: id).to_a
  end

  def self.list_all(object_type, user_id)
    object_type.where('instructor_id = ? AND private = 0', user_id)
  end


end
