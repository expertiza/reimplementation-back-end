class Suggestion < ApplicationRecord
  has_many :suggestion_comments, dependent: :delete_all

  validates :title, uniqueness: { case_sensitive: false }
  valicates :description, presence: true
end
