class Instructor < User
  has_many :assignments , foreign_key: 'instructor_id'
  # Get all users whose parent is the instructor
  def managed_users
    User.where(parent_id: id).to_a
  end


end
