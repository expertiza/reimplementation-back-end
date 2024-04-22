class Team < ApplicationRecord
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users
end