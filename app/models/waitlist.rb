class Waitlist < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :signed_up_team
end
