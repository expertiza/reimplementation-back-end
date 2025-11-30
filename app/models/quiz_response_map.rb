# frozen_string_literal: true

class QuizResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :quiz_questionnaire, foreign_key: 'reviewed_object_id', inverse_of: false
  belongs_to :assignment, inverse_of: false
  has_many :quiz_responses, foreign_key: :map_id, dependent: :destroy, inverse_of: false

  def questionnaire
    quiz_questionnaire
  end

  def self.mappings_for_reviewer(participant_id)
    QuizResponseMap.where(reviewer_id: participant_id)
  end

  def get_title
    QUIZ_RESPONSE_MAP_TITLE
  end
end