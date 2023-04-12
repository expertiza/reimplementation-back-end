class SignedUpTeam < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :team 

  # Get participants in the team signed up for a given topic.
  def find_team_participants()
    return team.get_team_participants()
  end 

  #This method is responsible for creating a signed_up_team for a topic by checking the condition if topic is available to choose.
  def self.create_signed_up_team(topic_identifier,team_id)
    signup_topic = SignupTopic.where(id: topic_identifier).first

    if signup_topic.find_if_topic_available() == false
      return false
    end

    signed_up_team = SignedUpTeam.new(signup_topic_id: topic_identifier,team_id: team_id)
    signed_up_team.save

    return true
  end

  #This method is responsible for deleting a signed_up_team for a topic and delegating any changes required in topic
  def self.delete_signed_up_team(team_id)
    signed_up_team = SignedUpTeam.where(id: team_id).first
    topic_release_status = signed_up_team.signup_topic.release_topic(signed_up_team.id)

    if topic_release_status == true
      signed_up_team.destroy
      return true
    else
      return false
    end

  end
end
