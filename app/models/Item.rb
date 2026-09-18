# frozen_string_literal: true

class Item < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire # each item belongs to a specific questionnaire
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
    self.seq = questionnaire.items.size + 1
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

  # Sum of weights for all scored items (excludes SectionHeaders).
  def self.total_item_weight(questionnaire)
    questionnaire.items.reject { |i| i.question_type == 'SectionHeader' }.sum(&:weight)
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