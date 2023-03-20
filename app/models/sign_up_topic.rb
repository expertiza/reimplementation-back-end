class SignUpTopic < ApplicationRecord
  has_many: :sign_up_team

  validates :name, :max_choosers, presence: true
  validates :topic_identifier, length: { maximum: 10 }

  def self.find_if_topic_available?()
    # NOTE: Use counter_cache:true in sign_up_team to get the count of has_many relations.
    return @sign_up_team.size < max_choosers
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

  def delete_topic(name)
    sign_up_topic = SignUpTopic.where(name: name).first
    sign_up_topic.destroy
  end

  def self.format_for_display()
    contents_for_display = ''
    contents_for_display += topic_identifier.to_s + ' - '
    topic_display + topic_name
  end

  def update_waitlisted_users()
    # TODO: This can be done after the waitlist model is built.
  end
end
