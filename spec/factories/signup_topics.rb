FactoryBot.define do
  factory :signup_topic do
    id {1}
    name {"topic_1"}
    max_choosers {1}
    category {"category_1"}
    topic_identifier {"topic_identifier_1"}
    description {"description_1"}
    link {"link_1"}
    assignment_id {1}
  end
end
