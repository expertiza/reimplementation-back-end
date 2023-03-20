class SignUpTopic < ApplicationRecord
  has_many: :sign_up_team

  validates :name, :max_choosers, presence: true
  validates :topic_identifier, length: { maximum: 10 }

  def self.find_available_slots?()
    p "TBD: Query for finding avilable slots goes here."
  end

  def create_topic()
    p "Create topic"
  end

  def update_topic()
    p "Update topic"
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
