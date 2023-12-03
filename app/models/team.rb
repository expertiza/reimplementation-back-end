class Team < ApplicationRecord
  # other model code...

  # Make sure 'name' attribute is defined
  validates :name, presence: true
end