class SignedUpTeam < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :team

  # This method is to get participants in the team signed up for a given topic. It calls on the parent Team Class to fetch the participants details.
  def get_team_participants
    return team.get_team_participants()
  end

  #This is a class method responsible for creating a SignedUpTeam instance with given topic_id and team_id by checking the condition if topic is available to choose.
  def self.create_signed_up_team(topic_id, team_id)
    signup_topic = SignupTopic.find(topic_id)

    if signup_topic.is_available() == false
      return false
    end

    signed_up_team = SignedUpTeam.create!({:signup_topic_id => topic_id, :team_id => team_id})

    return true
  end

  #This is a class method responsible for deleting a SignedUpTeam instance for a topic and delegating any changes required in topic
  def self.delete_signed_up_team(team_id)
    signed_up_team = SignedUpTeam.find(team_id)
    topic_release_status = signed_up_team.signup_topic.release_team(signed_up_team.id)

    if topic_release_status == true
      signed_up_team.destroy
      return true
    else
      return false
    end

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