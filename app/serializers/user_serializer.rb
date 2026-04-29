# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :fullName

  def username
    object.name
  end

  def fullName
    object.full_name
  end
end 
