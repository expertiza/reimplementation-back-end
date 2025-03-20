class SignedUpTeam < ApplicationRecord
  belongs_to :project_topic
  belongs_to :team
end
