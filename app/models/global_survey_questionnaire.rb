# frozen_string_literal: true

class GlobalSurveyQuestionnaire < Questionnaire
  after_initialize :post_initialization
  @print_name = 'Global Survey'

  def post_initialization
    self.display_type = 'Global Survey'
  end
end
