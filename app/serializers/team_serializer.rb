class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :max_team_size, :type, :team_size, :assignment_id
  has_many :users, serializer: UserSerializer

  def team_size
    object.team_members.count
  end
end 