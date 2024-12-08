class SuggestionComment < ApplicationRecord
  belongs_to :suggestion
  belongs_to :user

  validates :comment, presence: true
end
