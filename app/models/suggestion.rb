class Suggestion < ApplicationRecord
  belongs_to :assignment
  belongs_to :user
  has_many :suggestion_comments, dependent: :delete_all

  validates :title, uniqueness: { case_sensitive: false }
  validates :description, presence: true
end
