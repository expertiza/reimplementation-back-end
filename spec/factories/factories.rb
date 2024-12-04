FactoryBot.define do
    factory :user do
      name { "John Doe" }
    end
  
    factory :team do
      name { "Team A" }
      parent_id { 1 }
    end
  
    factory :teams_participant do
      association :user
      association :team
      duty_id { 1 }
    end
  
    factory :assignment do
      name { "Assignment 1" }
    end
  end
  

