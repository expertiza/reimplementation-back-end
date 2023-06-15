class Administrator < User
  def managed_users
    User.where(institution_id:).to_a
  end
end