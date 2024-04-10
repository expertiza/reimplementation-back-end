class Question < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire # each question belongs to a specific questionnaire
  has_many :answers, dependent: :destroy
  has_many :question_advices, dependent: :destroy # for each question, there is separate advice about each possible score
  
  validates :seq, presence: true, numericality: true # sequence must be numeric
  validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # user must define text content for a question
  validates :question_type, presence: true # user must define type for a question
  validates :break_before, presence: true

  def scorable?
    false
  end
    
  def set_seq
    self.seq = questionnaire.questions.size + 1
  end

  def as_json(options = {})
      super(options.merge({
                            only: %i[txt weight seq question_type size alternatives break_before min_label max_label created_at updated_at],
                            include: {
                              questionnaire: { only: %i[name id] }
                            }
                          })).tap do |hash|
      end
  end
end
