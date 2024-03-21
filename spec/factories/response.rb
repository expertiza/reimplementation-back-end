FactoryBot.define do
  factory :response do
    association :response_map
    additional_comment { 'Sample additional comment' }
    is_submitted { false }
    version_num { 1 }
    round { 1 }
    visibility { 'private' }
  end
end
