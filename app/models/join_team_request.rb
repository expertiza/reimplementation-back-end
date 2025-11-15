class JoinTeamRequest < ApplicationRecord
  belongs_to :team
  belongs_to :participant
  
  ACCEPTED_STATUSES = %w[ACCEPTED DECLINED PENDING]
  validates :reply_status, inclusion: { in: ACCEPTED_STATUSES }
end
