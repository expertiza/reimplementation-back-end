# frozen_string_literal: true

class Item < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire, inverse_of: :items # each item belongs to a specific questionnaire
  has_many :answers, dependent: :destroy, foreign_key: 'item_id'
  attr_accessor :choice_strategy
  
  validates :txt, length: { minimum: 0, allow_nil: false, message: "can't be nil" } # text content must be provided
  validates :question_type, presence: true # user must define the item type
  validates :break_before, inclusion: { in: [true, false] }
  validates :seq, presence: true, numericality: true, on: :update # sequence must be numeric
    
  def scorable?
    false
  end

  def scored?
    question_type&.downcase&.include?('scale') || question_type&.downcase&.include?('criterion')
  end
    
  def set_seq
    if questionnaire
      # Using items.size + 1 might be risky if items are not yet saved. 
      # Better to use a safe default if it's nil.
      self.seq ||= questionnaire.items.size + 1
    end
  end

  def as_json(options = {})
    super(options.merge({
                            only: %i[id txt weight seq question_type size alternatives break_before min_label max_label created_at updated_at],
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