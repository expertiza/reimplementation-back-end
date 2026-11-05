# frozen_string_literal: true

# API contract for users: `username` is the login, `name` is the display (full) name.
# The DB still stores these as `name` and `full_name`; once the columns are renamed to
# `username` and `name`, drop the mapping methods below and read the columns directly.
class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :name, :email,
             :email_on_review, :email_on_submission, :email_on_review_of_review,
             :role, :parent, :institution

  def username
    object.name
  end

  def name
    object.full_name
  end

  def role
    object.role&.slice(:id, :name)
  end

  def parent
    { id: object.parent&.id, name: object.parent&.full_name }
  end

  def institution
    { id: object.institution&.id, name: object.institution&.name }
  end
end
