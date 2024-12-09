class Question < ApplicationRecord
  before_validation :set_seq, on: :create
  belongs_to :questionnaire # each question belongs to a specific questionnaire
  has_many :answers, dependent: :destroy
  accepts_nested_attributes_for :answers # Allows nested attributes for answers

  validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # user must define text content for a question
  validates :question_type, presence: true # user must define type for a question
  validates :break_before, inclusion: { in: [true, false] }
  validates :correct_answer, presence: true
  validates :score_value, presence: true
  validates :skippable, inclusion: { in: [true, false] 


  def scorable?
    false
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


  private

  def set_seq
    if questionnaire.present?
      max_seq = questionnaire.questions.maximum(:seq)
      self.seq = max_seq.to_i + 1
    end
  end

end