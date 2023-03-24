class Instructor < User

  # Get all users whose parent is the instructor
  def manageable_users
    User.where(parent_id: id).to_a
  end
  
  
end
