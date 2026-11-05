# frozen_string_literal: true

# Full user shape, used wherever a user is rendered on its own (`render json: user`).
# Inherits the `username` / `name` contract from UserSummarySerializer.
class UserSerializer < UserSummarySerializer
  attributes :email_on_review, :email_on_submission, :email_on_review_of_review,
             :role, :parent, :institution

  def role
    object.role&.slice(:id, :name)
  end

  def parent
    { id: object.parent&.id, name: object.parent && UserSummarySerializer.new(object.parent).name }
  end

  def institution
    { id: object.institution&.id, name: object.institution&.name }
  end
end
