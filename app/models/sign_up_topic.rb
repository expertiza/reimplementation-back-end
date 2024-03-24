class SignUpTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: 'topic_id', dependent: :destroy
  has_many :teams, through: :signed_up_teams # list all teams choose this topic, no matter in waitlist or not
  has_many :due_dates, class_name: 'TopicDueDate', foreign_key: 'parent_id', dependent: :destroy
  has_many :bids, foreign_key: 'topic_id', dependent: :destroy
  has_many :assignment_questionnaires, class_name: 'AssignmentQuestionnaire', foreign_key: 'topic_id', dependent: :destroy
  belongs_to :assignment

#   has_paper_trail

end