class Answer < ApplicationRecord
    belongs_to :response
    belongs_to :item, foreign_key: 'question_id'
end
