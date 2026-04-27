# frozen_string_literal: true

class Item < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire, optional: true, inverse_of: :items
  has_many :answers, dependent: :destroy, foreign_key: 'item_id'
  attr_accessor :choice_strategy
  
  validates :seq, presence: true, numericality: true # sequence must be numeric
  validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # text content must be provided
  validates :question_type, presence: true # user must define the item type
  validates :break_before, presence: true

  def scorable?
    false
  end

  def scored?
    question_type.in?(%w[ScaleItem CriterionItem])
  end
    
  def set_seq
    if questionnaire
      self.seq ||= questionnaire.items.size + 1
    else
      self.seq ||= 1
    end
  end

  # Item types that are permitted inside a Quiz questionnaire and that the
  # scoring pipeline knows how to evaluate. Used by {QuestionsController} for
  # input validation and by {Response#aggregate_questionnaire_score} to decide
  # which scoring branch to use.
  QUIZ_ITEM_TYPES = %w[TextField MultipleChoiceRadio MultipleChoiceCheckbox Scale Checkbox].freeze

  # Returns +true+ when this item belongs to a questionnaire whose type is
  # "Quiz" or "QuizQuestionnaire".
  #
  # Used to conditionally expose +correct_answer+ in {#as_json} and to
  # enforce the {#correct_answer_only_for_quiz} validation.
  #
  # @return [Boolean]
  def is_quiz_item?
    %w[Quiz QuizQuestionnaire].include?(questionnaire&.questionnaire_type)
  end

  validate :correct_answer_only_for_quiz

  # Validates that +correct_answer+ is only set on items that belong to a
  # quiz questionnaire. Prevents instructors from accidentally adding a
  # correct-answer constraint to peer-review rubric items.
  #
  # @return [void]
  def correct_answer_only_for_quiz
    if correct_answer.present? && !is_quiz_item?
      errors.add(:correct_answer, 'can only be set on items belonging to a Quiz questionnaire')
    end
  end

  # Serialises the item to a JSON-safe hash for API responses.
  #
  # The +correct_answer+ field is included only when {#is_quiz_item?} is +true+
  # so that it is never accidentally exposed on peer-review rubric items.
  # The nested +questionnaire+ object includes +questionnaire_type+ so the
  # frontend can distinguish quiz items from review items without a second
  # request. A synthetic +is_quiz_item+ boolean is appended to the hash.
  #
  # @param options [Hash] standard ActiveModel::Serializers::JSON options
  # @return [Hash] the serialised item
  def as_json(options = {})
    only_fields = %i[
      id txt weight seq question_type size alternatives break_before
      min_label max_label created_at updated_at textarea_width
      textarea_height textbox_width col_names row_names
    ]
    only_fields << :correct_answer if is_quiz_item?

    super(options.merge({
                          only: only_fields,
                          include: {
                            questionnaire: { only: %i[name id questionnaire_type] }
                          }
                        })).tap do |hash|
      hash['is_quiz_item'] = is_quiz_item?
    end
  end

  def strategy
    case question_type
    when 'dropdown'
      self.choice_strategy = Strategies::DropdownStrategy.new
    when 'multiple_choice'
      self.choice_strategy = Strategies::MultipleChoiceStrategy.new
    when 'scale'
      self.choice_strategy = Strategies::ScaleStrategy.new
    else
      raise "Unknown item type: #{question_type}"
    end
  end

  # Use strategy to render the item
  def render
    strategy.render(self)
  end

  # Use strategy to validate the item
  def validate_item
    strategy.validate(self)
  end

  def max_score
    weight
  end

  def self.for(record)
    klass = case record.question_type
            when 'Criterion'
              Criterion
            when 'Scale'
              Scale
            else
              Item
            end

    # Cast the existing record to the desired subclass
    klass.new(record.attributes)
  end

  def max_score
    weight
  end

  def self.for(record)
    klass = case record.question_type
            when 'Criterion'
              Criterion
            when 'Scale'
              Scale
            else
              Item
            end

    # Cast the existing record to the desired subclass
    klass.new(record.attributes)
  end
end