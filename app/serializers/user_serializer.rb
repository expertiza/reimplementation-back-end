class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :full_name
end 
