class ParticipantSerializer < ActiveModel::Serializer
    attributes :id, :user, :parent_id, :user_id, :authorization

    def user
        {
            id: object.user.id,
            username: object.user.username,
            email: object.user.email,
            name: object.user.name
        }
    end
end
