class SignUpTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: 'sign_up_topic_id', dependent: :destroy
  belongs_to :assignment
end
