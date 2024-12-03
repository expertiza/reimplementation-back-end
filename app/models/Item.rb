class Item < ApplicationRecord
  before_create :set_seq
  belongs_to :questionnaire # each question belongs to a specific questionnaire
  has_many :answers, dependent: :destroy
  has_many :choices, dependent: :destroy
  attr_accessor :choice_rendering_strategy
  
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

  def set_rendering_strategy
    case self.class.name
    when "DropdownItem"
      self.choice_rendering_strategy = DropdownRenderingStrategy.new
    when "MultipleChoiceItem"
      self.choice_rendering_strategy = MultipleChoiceRenderingStrategy.new
    when "ScaleItem"
      self.choice_rendering_strategy = ScaleRenderingStrategy.new
    else
      # Default strategy
      self.choice_rendering_strategy = ChoiceRenderingStrategy.new
    end
  end

  # Render the item choices using the selected strategy
  def render
    choice_rendering_strategy.render_choices(self)
  end
end
