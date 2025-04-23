class TeamMember < ApplicationRecord
  belongs_to :team
  belongs_to :user

  validates :team, presence: true
  validates :user, presence: true
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :team_id }

  enum :role, { member: 'member', admin: 'admin' }

  after_initialize :set_default_role, if: :new_record?

  def promote_to_admin!
    update!(role: :admin)
  end

  def demote_to_member!
    update!(role: :member)
  end

  private

  def set_default_role
    self.role ||= :member
  end
end 