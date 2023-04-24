class SignupTopicSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :category, :topic_identifier, :description, :link
  attributes :num_waitlisted do |object|
    Waitlist.count_waitlisted_teams(object.id)
  end
  attributes :available_slots do |object|
    object.count_available_slots
  end

  attributes :signed_up_teams
end
