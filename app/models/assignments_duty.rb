class AssignmentsDuty < ApplicationRecord
  belongs_to :assignment
  belongs_to :duty

  validates :max_members_for_duty, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
end