class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users
  belongs_to :assignment
end