class Answer < ApplicationRecord
    belongs_to :response
    belongs_to :question
end
  