class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire
  belongs_to :sign_up_topic, class_name: 'SignUpTopic', foreign_key: 'topic_id'
end
