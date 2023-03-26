class Instructor < ApplicationRecord
  # Holds information about the user type: Instructor
  has_many :questionnaires
end
