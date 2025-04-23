class TeamJoinRequestSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :team_id, :status
  belongs_to :user
  belongs_to :team
end 