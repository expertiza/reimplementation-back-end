class Participant < ApplicationRecord
  belongs_to :user

  def fullname(ip_address = nil)
    user.fullname(ip_address)
  end
end
