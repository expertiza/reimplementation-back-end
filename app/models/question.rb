class Question < ApplicationRecord
  has_many :answers, dependent: :destroy
end
