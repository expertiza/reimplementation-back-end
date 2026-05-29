# frozen_string_literal: true

class AnswerTag < ApplicationRecord
  belongs_to :answer
  belongs_to :tag_prompt_deployment
  belongs_to :user

  scope :for_deployment, ->(deployment_id) { where(tag_prompt_deployment_id: deployment_id) }

  validates :answer_id,               presence: true
  validates :tag_prompt_deployment_id, presence: true
  validates :user_id,                 presence: true
  validates :value,                   presence: true
end
