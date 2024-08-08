class Question < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire # each question belongs to a specific questionnaire
  has_many :answers, dependent: :destroy
  has_many :quiz_question_choices, class_name: 'QuizQuestionChoice', foreign_key: 'question_id'

  validates :seq, presence: true, numericality: true # sequence must be numeric
  validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # user must define text content for a question
  validates :question_type, presence: true # user must define type for a question
  validates :break_before, presence: true

  QUESTION_TYPES = {
    'MultipleChoiceCheckbox' => :calculate_score_for_checkbox_question,
    'TrueFalse' => :calculate_score_for_truefalse_question,
    'MultipleChoiceRadio' => :calculate_score_for_truefalse_question
  }.freeze

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

  # Calculates the score for a question based on the type and user answers
  def calculate_score(params)
    correct_answers = quiz_question_choices.where(iscorrect: true)
    user_answers = params[id.to_s]

    case question_type
    when 'MultipleChoiceCheckbox'
      calculate_score_for_checkbox_question(correct_answers, user_answers)
    when 'TrueFalse', 'MultipleChoiceRadio'
      calculate_score_for_truefalse_question(correct_answers.first, user_answers)
    else
      0 # Default score for unsupported question types
    end
  end

  private

  # Calculates score for MultipleChoiceCheckbox type questions
  def calculate_score_for_checkbox_question(correct_answers, user_answers)
    return 0 if user_answers.nil?

    score = 0
    correct_answers.each do |correct|
      score += 1 if user_answers.include?(correct.txt)
    end

    score == correct_answers.count && score == user_answers.count ? 1 : 0
  end

  # Calculates score for TrueFalse and MultipleChoiceRadio type questions
  def calculate_score_for_truefalse_question(correct_answer, user_answer)
    correct_answer.txt == user_answer ? 1 : 0
  end
end
