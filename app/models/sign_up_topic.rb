class SignUpTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: 'sign_up_topic_id', dependent: :destroy
  has_many :teams, through: :signed_up_teams
  has_many :assignment_questionnaires, class_name: 'AssignmentQuestionnaire', foreign_key: 'topic_id', dependent: :destroy
  has_many :due_dates, as: :parent, class_name: 'DueDate', dependent: :destroy
  belongs_to :assignment
end
