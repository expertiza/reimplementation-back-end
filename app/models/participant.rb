class Participant < ApplicationRecord
  validates :grade, numericality: { allow_nil: true }

end