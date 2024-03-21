# frozen_string_literal: true

class ChoiceQuestion < Question
  def scorable?
    false
  end
end
