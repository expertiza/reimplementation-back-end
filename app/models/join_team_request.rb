class JoinTeamRequest < ApplicationRecord
  belongs_to :team
  has_one :participant, dependent: :nullify
end
