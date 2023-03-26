# Initial commit
class Criterion < ScoredQuestion
  include ActionView::Helpers
  validates :size, presence: true
  
end
