# frozen_string_literal: true

class SignUpTopic < ApplicationRecord
  include DueDateActions
  has_many :signed_up_teams, foreign_key: 'topic_id', dependent: :destroy
  has_many :teams, through: :signed_up_teams # list all teams choose this topic, no matter in waitlist or not
  has_many :assignment_questionnaires, class_name: 'AssignmentQuestionnaire', foreign_key: 'topic_id', dependent: :destroy
  # Note: due_dates association is provided by DueDateActions mixin
  belongs_to :assignment
end
