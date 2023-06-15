class SuperAdministrator < User
  def manageable_users
    User.all.to_a
  end
end