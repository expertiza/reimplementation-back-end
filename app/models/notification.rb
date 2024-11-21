class Notification < ApplicationRecord
  validates :subject, presence: true
  validates :description, presence: true
  validates :expiration_date, presence: true
  belongs_to :course
  belongs_to :user
end
