class Waitlist < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :signed_up_team
end
