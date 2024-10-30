class BookmarkRating < ApplicationRecord
  belongs_to :bookmark
  belongs_to :user
  validates :rating, presence: true
end
