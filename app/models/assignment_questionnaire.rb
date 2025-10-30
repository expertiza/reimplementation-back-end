# frozen_string_literal: true

class AssignmentQuestionnaire < ApplicationRecord
  belongs_to :assignment
  belongs_to :questionnaire
  belongs_to :topic, class_name: 'SignUpTopic', foreign_key: 'topic_id', optional: true
end
