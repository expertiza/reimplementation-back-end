class Participant < ApplicationRecord
  belongs_to :user
  belongs_to: assignment

  def fullname(ip_address = nil)
    user.fullname(ip_address)
  end
end
