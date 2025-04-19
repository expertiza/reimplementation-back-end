class Answer < ApplicationRecord
    belongs_to :response
    # belongs_to :item, class_name: 'Item', foreign_key: 'question_id'
end
