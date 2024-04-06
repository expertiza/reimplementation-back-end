class Assignment < ApplicationRecord
  include MetricHelper
  has_many :invitations
  has_many :questionnaires
  has_many :participants, class_name: 'AssignmentParticipant', foreign_key: 'parent_id', dependent: :destroy

  def review_questionnaire_id
    Questionnaire.find_by_assignment_id id
  end

  def num_review_rounds
    rounds_of_reviews
  end
  #added a dummy method for assignment_participant file
  def team_reviewing_enabled

  end
  def path

  end
end
