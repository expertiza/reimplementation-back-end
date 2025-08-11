class JoinTeamRequest < ApplicationRecord
  # TODO Uncomment the following line when Team and Team Controller is thoroughly implemented
  # belongs_to :team
  has_one :participant, dependent: :nullify
  ACCEPTED_STATUSES = %w[ACCEPTED DECLINED PENDING]
  validates :status, inclusion: { in: ACCEPTED_STATUSES }
end
