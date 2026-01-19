class ParticipantSerializer < ActiveModel::Serializer
    attributes :id, :user, :user_id, :parent_id, :authorization

    def user
        {
            id: object.user.id,
            username: object.user.name,
            email: object.user.email,
            fullName: object.user.full_name
        }
    end
end