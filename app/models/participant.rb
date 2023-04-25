class Participant < ApplicationRecord
  belongs_to :user
  belongs_to :assignment, foreign_key: 'parent_id', inverse_of: false

  def fullname(ip_address = nil)
    user.fullname(ip_address)
  end
end
