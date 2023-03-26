# Initial commit
class Criterion < ScoredQuestion
  # Defines methods for Criteriod type question within a questionnaire
  include ActionView::Helpers
  validates :size, presence: true
  
end
