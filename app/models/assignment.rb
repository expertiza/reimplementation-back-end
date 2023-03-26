class Assignment < ApplicationRecord
  # Assignment created by an instructor or administrator
  has_many :assignment_questionnaires
end
