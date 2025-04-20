class TeamMemberSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :team_id
  belongs_to :user
  belongs_to :team
end 