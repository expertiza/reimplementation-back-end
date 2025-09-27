# frozen_string_literal: true

class SuperAdministrator < User
  def managed_users
    User.all.to_a
  end
end