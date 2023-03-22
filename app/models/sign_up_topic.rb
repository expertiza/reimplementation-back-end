class SignUpTopic < ApplicationRecord
  belongs_to :assignment
  validates_uniqueness_of :topic_name, scope: :assignment_id
end
