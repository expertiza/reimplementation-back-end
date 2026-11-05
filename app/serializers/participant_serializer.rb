class ParticipantSerializer < ActiveModel::Serializer
    attributes :id, :user, :parent_id, :user_id, :authorization

    # Same user contract as UserSerializer: username = login, name = full name
    def user
        UserSummarySerializer.new(object.user).as_json
    end
end
