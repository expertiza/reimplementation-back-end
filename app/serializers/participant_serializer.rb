class ParticipantSerializer < ActiveModel::Serializer
    attributes :id, :user

    def user
        {
            id: object.user.id,
            username: object.user.name,
            email: object.user.email,
            fullName: object.user.full_name
        }
    end
end