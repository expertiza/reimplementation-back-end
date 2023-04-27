class SignedUpTeam < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :team 

  # This method is to get participants in the team signed up for a given topic. It calls on the parent Team Class to fetch the participants details.
  def team_participants()
    return team.team_participants()
  end 

  # This is a class method responsible for creating a SignedUpTeam instance with given topic_id and team_id by checking the condition if topic is available to choose.
  def self.create_signed_up_team(topic_id, team_id)
    signup_topic = SignupTopic.find(topic_id)

    if signup_topic.is_available? == false
      signed_up_team = SignedUpTeam.create!({:signup_topic_id => topic_id, :team_id => team_id, :is_waitlisted => true })
    else
      signed_up_team = SignedUpTeam.create!({:signup_topic_id => topic_id, :team_id => team_id})
    end
    return true
  end

  # This method overrides the default destory method to trigger signup topic and waitlist related updates.
  def destroy
    self.signup_topic.promote_waitlisted_team
    super
  end
end
