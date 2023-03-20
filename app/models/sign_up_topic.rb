class SignUpTopic < ApplicationRecord
  has_many: :sign_up_team

  validates :name, :max_choosers, presence: true
  validates :topic_identifier, length: { maximum: 10 }

  def self.find_available_slots?()
    p "TBD: Query for finding avilable slots goes here."
  end

  def create_topic(name, max_choosers, category, topic_identifier, description)
    sign_up_topic = SignUpTopic.new
    sign_up_topic.name = name
    sign_up_topic.max_choosers = max_choosers
    sign_up_topic.category = category
    sign_up_topic.topic_identifier = topic_identifier
    sign_up_topic.description = description
    sign_up_topic.save
  end

  def update_topic(name, max_choosers, category, description)
    sign_up_topic = SignUpTopic.where(name: name).first
    sign_up_topic.max_choosers = max_choosers
    sign_up_topic.category = category
    sign_up_topic.description = description
    sign_up_topic.save
  end

  def delete_topic()
    p "Delete topic"
  end

  def format_for_display()
    p "Format for display"
  end

  def update_waitlisted_users()
    p "Update waitlisted users"
  end
end
