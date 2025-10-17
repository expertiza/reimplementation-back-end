class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :team_size
  has_many :members, serializer: UserSerializer

  def members
    # Use teams_participants association to get users
    object.teams_participants.includes(:user).map(&:user)
  end

  def team_size
    object.teams_participants.count
  end

end