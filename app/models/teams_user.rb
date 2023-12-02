class TeamsUser < ApplicationRecord
  #empty method added
  belongs_to :user
  belongs_to :team
end