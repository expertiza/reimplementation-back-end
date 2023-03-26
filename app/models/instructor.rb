class Instructor < User
  # Holds information about the user type: Instructor
  has_many :questionnaires

  # Get all users whose parent is the instructor
  def manageable_users
    User.where(parent_id: id).to_a
  end  
end
