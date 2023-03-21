class SignUpTopic < ApplicationRecord
  has_many :sign_up_team

  validates :name, :max_choosers, presence: true
  validates :topic_identifier, length: { maximum: 10 }

  # Find if a topic is available for further selection. Topic is considered available if the
  # total number of teams assigned to the topic are less than the maximum choosers allowed.
  def find_if_topic_available?()
    # NOTE: Use counter_cache:true in sign_up_team to get the count of has_many relations.
    return @sign_up_team.size < max_choosers
  end

  # Create topic for signing up. Requires name, maximum allowed, category, topic and 
  # brief description to be shown in the sign-up sheet.
  def self.create_topic(name, max_choosers, category, topic_identifier, description)
    sign_up_topic = SignUpTopic.new
    sign_up_topic.name = name
    sign_up_topic.max_choosers = max_choosers
    sign_up_topic.category = category
    sign_up_topic.topic_identifier = topic_identifier
    sign_up_topic.description = description
    sign_up_topic.save
    return sign_up_topic
  end

  # Update max choosers | category | description based on name i.e., primary key.
  # NOTE: Save cannot be done on instance methods.
  def self.update_topic(name, max_choosers, category, description)
    sign_up_topic = SignUpTopic.where(name: name).first
    sign_up_topic.max_choosers = max_choosers
    sign_up_topic.category = category
    sign_up_topic.description = description
    sign_up_topic.save
    return sign_up_topic
  end

  # Delete topic based on primary key i.e., name of topic.
  # NOTE: Destroy cannot be done on instance methods.
  def self.delete_topic(name)
    sign_up_topic = SignUpTopic.where(name: name).first
    sign_up_topic.destroy
  end

  # Format the given active record for display.
  def format_for_display()
    contents_for_display = ''
    contents_for_display += topic_identifier.to_s + ' - ' + name.to_s
  end

  # Send update to all waitlisted users regarding waitlist changes.
  def self.update_waitlisted_users()
    # TODO: This can be done after the waitlist model is built.
  end
end
