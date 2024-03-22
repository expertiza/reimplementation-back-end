class Answer < ApplicationRecord
    belongs_to :question
    validates :answer_text, presence: true
    validates :correct, inclusion: {in: [true, false]}
end
