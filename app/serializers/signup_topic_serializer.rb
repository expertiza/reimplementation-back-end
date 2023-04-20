class SignupTopicSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :category, :topic_identifier, :description, :link
  belongs_to :assignment
  has_many :signed_up_teams
end
