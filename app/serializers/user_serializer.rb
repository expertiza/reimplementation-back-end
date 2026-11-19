# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :name,
             :email_on_review, :email_on_submission, :email_on_review_of_review,
             :role, :parent, :institution

  # Same shapes as User#as_json; missing associations become { id: nil, ... } rather than nil
  def role
    { id: object.role&.id, name: object.role&.name }
  end

  def parent
    { id: object.parent&.id, username: object.parent&.username }
  end

  def institution
    { id: object.institution&.id, name: object.institution&.name }
  end
end
