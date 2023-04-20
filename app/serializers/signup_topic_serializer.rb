class SignupTopicSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :category, :topic_identifier, :description, :link, :signed_up_teams
end
