class ParticipantSerializer < ActiveModel::Serializer
    attributes :id, :user, :parent_id, :user_id, :authorization, :duty_id, :duty_name

    def user
        {
            id: object.user.id,
            username: object.user.name,
            email: object.user.email,
            fullName: object.user.full_name
        }
    end

    def duty_name
      object.duty&.name
    end
end
