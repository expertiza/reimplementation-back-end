class SignedUpTeam < ApplicationRecord
  def drop_team
    true
  end
  def self.find_team_participants(assignment_id)
    #assignment_id
    { data:[
        {
          "id": 123,
          "topic_identifier": "E2333",
          "topic_name": "Github metrics integration",
          "max_choosers": 1,
          "available_slots": 0,
          "num_waitlisted": 1,
          "signed_up_teams": [
            {
              "signed_up_team_id": 123,
              "is_waitlisted": false,
              "team_members": [
                {
                  "name": "John Doe"
                },
                {
                  "name": "Jane Doe"
                }
              ]
            },
            {
              "signed_up_team_id": 124,
              "is_waitlisted": true,
              "team_members": [
                {
                  "name": "John Doe"
                },
                {
                  "name": "Jane Doe"
                }
              ]
            }
          ]
        },
        {
          "id": 124,
          "topic_identifier": "E2334",
          "topic_name": "Github metrics integration",
          "max_choosers": 1,
          "available_slots": 0,
          "num_waitlisted": 1,
          "signed_up_teams": [
            {
              "signed_up_team_id": 123,
              "is_waitlisted": false,
              "team_members": [
                {
                  "name": "John Doe"
                },
                {
                  "name": "Jane Doe"
                }
              ]
            },
            {
              "signed_up_team_id": 124,
              "is_waitlisted": true,
              "team_members": [
                {
                  "name": "John Doe"
                },
                {
                  "name": "Jane Doe"
                }
              ]
            }
          ]
        }
      ]}
  end
end