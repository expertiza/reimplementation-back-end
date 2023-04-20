class SignedUpTeamSerializer
  include JSONAPI::Serializer
  attributes :id, :is_waitlisted, :team_id, :preference_priority_number
end
