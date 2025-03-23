class Question < ApplicationRecord
    belongs_to :questionnaire  # each question belongs to a specific questionnaire
    # belongs_to :review_of_review_score  # ditto
    has_many :question_advices, dependent: :destroy  # for each question, there is separate advice about each possible score
    has_many :signup_choices  # this may reference signup type questionnaires
    has_many :answers, dependent: :destroy
  
    validates :seq, presence: true  # user must define sequence for a question
    validates :seq, numericality: true  # sequence must be numeric
    validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" }  # user must define text content for a question
    # validates :type, presence: true  # user must define type for a question
    validates :break_before, presence: true
  

end
  