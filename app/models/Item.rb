# frozen_string_literal: true

class Item < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire, optional: true
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

  QUIZ_ITEM_TYPES = %w[TextField MultipleChoiceRadio MultipleChoiceCheckbox Scale Checkbox].freeze

  def is_quiz_item?
    %w[Quiz QuizQuestionnaire].include?(questionnaire&.questionnaire_type)
  end

  validate :correct_answer_only_for_quiz

  def correct_answer_only_for_quiz
    if correct_answer.present? && !is_quiz_item?
      errors.add(:correct_answer, 'can only be set on items belonging to a Quiz questionnaire')
    end
  end

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