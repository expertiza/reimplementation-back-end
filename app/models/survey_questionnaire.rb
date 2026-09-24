# frozen_string_literal: true

class SurveyQuestionnaire < Questionnaire
  after_initialize :post_initialization
  @print_name = 'Survey'

  def post_initialization
    self.display_type = 'Survey'
  end
end
