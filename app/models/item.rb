# frozen_string_literal: true

class Item < ApplicationRecord
  # All valid item types supported by the application.
  # Used by ItemsController#types to return the list to the front-end,
  # and can be used elsewhere for validation or display.
  ITEM_TYPES = ['Criterion', 'Scale', 'Dropdown', 'Multiple choice', 'Text area', 'Text field', 'Grid'].freeze
  QUESTION_TYPES = ITEM_TYPES

  alias_attribute :question_type, :item_type

  before_create :set_seq
  belongs_to :questionnaire, inverse_of: :items # each item belongs to a specific questionnaire
  has_many :answers, dependent: :destroy, foreign_key: 'item_id'
  attr_accessor :choice_strategy

  validates :seq, presence: true, numericality: true # sequence must be numeric
  validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # text content must be provided
  validates :item_type, presence: true # user must define the item type
  validates :break_before, presence: true

  def scorable?
    false
  end

  def scored?
    item_type.in?(%w[ScaleItem CriterionItem])
  end

  # Sets the sequence number for a new item if not already provided.
  # Defaults to the next sequential position based on existing items in the questionnaire.
  def set_seq
    self.seq ||= (questionnaire&.items&.reject { |i| i == self }&.size || 0) + 1
  end

  def as_json(options = {})
    super(options.merge({
                          only: %i[id txt weight seq item_type size alternatives break_before min_label max_label
                                   created_at updated_at],
                          methods: %i[question_type],
                          include: {
                            questionnaire: { only: %i[name id] }
                          }
                        })).tap do |hash|
    end
  end

  def strategy
    case item_type
    when 'dropdown'
      self.choice_strategy = Strategies::DropdownStrategy.new
    when 'multiple_choice'
      self.choice_strategy = Strategies::MultipleChoiceStrategy.new
    when 'scale'
      self.choice_strategy = Strategies::ScaleStrategy.new
    else
      raise "Unknown item type: #{item_type}"
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

  # Sum of weights for all scored items (excludes SectionHeaders).
  def self.total_item_weight(questionnaire)
    questionnaire.items.reject { |i| i.item_type == 'SectionHeader' }.sum(&:weight)
  end

  # Duplicates this item into the given questionnaire, including its advice records.
  def copy(questionnaire)
    new_item = dup
    new_item.questionnaire_id = questionnaire.id
    new_item.size = '50,3' if new_item.size.nil? && (new_item.is_a?(Criterion) || new_item.is_a?(TextResponse))
    new_item.save!
    QuestionAdvice.where(question_id: id).each do |advice|
      new_advice = advice.dup
      new_advice.question_id = new_item.id
      new_advice.save!
    end
    new_item
  end

  def self.for(record)
    klass = case record.item_type
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
