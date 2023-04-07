class SignedUpTeam < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :team
end
