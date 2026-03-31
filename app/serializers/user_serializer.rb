# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :full_name, :email_on_review, :email_on_submission,
             :email_on_review_of_review, :date_format_pref, :created_at, :updated_at,
             :role, :parent, :institution

  def role
    return nil unless object.role

    {
      id: object.role.id,
      name: object.role.name
    }
  end

  def parent
    return { id: nil, name: nil } unless object.parent

    {
      id: object.parent.id,
      name: object.parent.name
    }
  end

  def institution
    return { id: nil, name: nil } unless object.institution

    {
      id: object.institution.id,
      name: object.institution.name
    }
  end

  def date_format_pref
    nil
  end
end 
