class Invitation < ApplicationRecord
  belongs_to :to_user, class_name: 'User', foreign_key: 'to_id', inverse_of: false
  belongs_to :from_user, class_name: 'User', foreign_key: 'from_id', inverse_of: false
  belongs_to :assignment, class_name: 'Assignment', foreign_key:   'assignment_id'
  validates :reply_status, presence: true, length: { maximum: 1 }
  validates_inclusion_of :reply_status, in: %w[W A R], allow_nil: false
  validate :to_from_cant_be_same

  # validate if the to_id and from_id are same
  def to_from_cant_be_same
    if self.from_id == self.to_id
      errors.add(:from_id, "to and from users should be different")
    end
  end
end
