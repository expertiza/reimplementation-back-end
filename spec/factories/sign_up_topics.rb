FactoryBot.define do
    factory :sign_up_topic do
        sequence("topic_name") { |n| "Topic #{n}" }

        # Grab an assignment ID
        assignment_id { Assignment.first&.id || association(:assignment).id }
    end
end
