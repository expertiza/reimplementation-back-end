# frozen_string_literal: true

class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :team_size, :max_team_size, :parent_id, :parent_type
  has_many :users, serializer: UserSerializer

  def users
    object.teams_participants.includes(:user).map(&:user)
  end

  def team_size
    object.size
  end

  # Use polymorphic method instead of type checking
  def max_team_size
    object.max_team_size
  end

  def parent_id
    object.parent_id
  end

  def parent_type
    object.context_label
  end
end
