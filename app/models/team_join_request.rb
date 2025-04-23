class TeamJoinRequest < ApplicationRecord
  belongs_to :team
  belongs_to :user

  validates :team, presence: true
  validates :user, presence: true
  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :team_id, message: 'already has a join request for this team' }

  enum :status, { pending: 'pending', accepted: 'accepted', rejected: 'rejected' }

  after_initialize :set_default_status, if: :new_record?

  def accept!
    transaction do
      update!(status: :accepted)
      team.team_members.create!(user: user)
    end
  end

  def reject!
    update!(status: :rejected)
  end

  private

  def set_default_status
    self.status ||= :pending
  end
end 