class Participant < ApplicationRecord
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false

  # Find Team based on the user.
  def team
    TeamsUser.find_by(users_id: user).try(:team)
  end

  def fullname
    user.full_name
  end
end