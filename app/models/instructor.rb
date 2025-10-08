# frozen_string_literal: true

class Instructor < User

  # Get all users whose parent is the instructor
  def managed_users
    User.where(parent_id: id).to_a
  end


end
