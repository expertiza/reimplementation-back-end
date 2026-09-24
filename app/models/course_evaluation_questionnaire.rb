# frozen_string_literal: true

class CourseEvaluationQuestionnaire < Questionnaire
  after_initialize :post_initialization
  @print_name = 'Course Evaluation'

  def post_initialization
    self.display_type = 'Course Evaluation'
  end
end
