class Administrator < User
  def manageable_users
    User.where(institution_id:).to_a
  end
end