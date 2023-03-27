class Ta < User
  # Get all users whose parent is the TA
  # @return [Array<User>] all users that belongs to courses that is mapped to the TA
  def manageable_users
    User.where(parent_id: id).to_a
  end

  def my_instructor
    # code here
  end
end