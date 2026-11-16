class ParticipantSerializer < ActiveModel::Serializer
    attributes :id, :user, :parent_id, :user_id, :authorization

    def user
        user = object.user
        {
            id: user.id,
            username: user.username,
            email: user.email,
            name: user.name,
            email_on_review: user.email_on_review,
            email_on_submission: user.email_on_submission,
            email_on_review_of_review: user.email_on_review_of_review,
            # Same shapes as User#as_json, so the participant editor can prefill its form
            role: { id: user.role&.id, name: user.role&.name },
            parent: { id: user.parent&.id, username: user.parent&.username },
            institution: { id: user.institution&.id, name: user.institution&.name }
        }
    end
end
