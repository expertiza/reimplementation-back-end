# frozen_string_literal: true

class ScoredItem < ChoiceItem
  validates :weight, presence: true # user must specify a weight for a question
  validates :weight, numericality: true # the weight must be numeric
  
  validates :weight, presence: true # user must specify a weight for a question
  validates :weight, numericality: true # the weight must be numeric
  
  def scorable?
      true
  end

  def self.compute_item_score(response_id)
    answer = Answer.find_by(item_id: id, response_id: response_id)
    weight * answer.answer
  end
  end

  def self.compute_item_score(response_id)
    answer = Answer.find_by(item_id: id, response_id: response_id)
    weight * answer.answer
  end
end
