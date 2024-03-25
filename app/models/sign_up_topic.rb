class SignUpTopic < ApplicationRecord
  validates :topic_name, :assignment_id, :max_choosers, presence: true
  validates :topic_identifier, length: { maximum: 10 }

end
