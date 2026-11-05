# frozen_string_literal: true

# Minimal user shape for embedding a user inside other records (participants, invitations, reports).
#
# API contract for users: `username` is the login, `name` is the display (full) name.
# The DB still stores these as `name` and `full_name`. This is the only place that maps
# columns to that contract: once the columns are renamed to `username` and `name`, delete
# the two methods below and the attributes read the columns directly.
class UserSummarySerializer < ActiveModel::Serializer
  attributes :id, :username, :name, :email

  def username
    object.name
  end

  def name
    object.full_name
  end
end
