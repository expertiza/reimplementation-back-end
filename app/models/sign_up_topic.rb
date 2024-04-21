class SignUpTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: 'topic_id', dependent: :destroy
  has_many :teams, through: :signed_up_teams # list all teams choose this topic, no matter in waitlist or not
  has_many :assignment_questionnaires, class_name: 'AssignmentQuestionnaire', foreign_key: 'topic_id', dependent: :destroy
  belongs_to :assignment

  # the below relations have been added to make it consistent with the database schema
  validates :topic_name, :assignment_id, :max_choosers, presence: true
  validates :topic_identifier, length: { maximum: 10 }

end
