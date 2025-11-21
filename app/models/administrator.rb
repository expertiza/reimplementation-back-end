# frozen_string_literal: true

class Administrator < User
  def managed_users
    # Get all users that belong to an institution of the loggedIn user except the user itself
    User.where(institution_id:).where.not(id:)
  end
end
