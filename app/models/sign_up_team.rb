class SignUpTeam < ApplicationRecord
  belongs_to :sign_up_topic, counter_cache:true
  belongs_to :team
  
  validates :is_waitlisted, presence: true 

  # Get participants in the team signed up for the given topic.
  def find_team_participants()
    return team.get_team_participants()
  end

  def release_topics()
    # TODO: Update waitlist and release topics.
  end

  #Create a signUp team with the given parameters topic_id and is_waitlisted 
  def self.create_sign_up_team(is_waitlisted, topic_identifier, teams_id)
    sign_up_topic = SignUpTopic.where(topic_identifier: topic_identifier).first

    if sign_up_topic.find_if_topic_available? == false
      return
    end

    sign_up_team = SignUpTeam.new
    sign_up_team.is_waitlisted=is_waitlisted
    sign_up_team.sign_up_topic_id=topic_identifier
    sign_up_team.teams_id=teams_id
    sign_up_team.save
    return sign_up_team
  end

  #When a team sign up for a topic and they want to opt out from that topic
  #this function is called to destroy that record
  def self.delete_sign_up_team(teams_id)
    sign_up_team = SignUpTeam.where(teams_id: teams_id).first
    sign_up_team.destroy
  end

  #Update the sign up team for a topic and update the records.
  def self.update_sign_up_team(teams_id,is_waitlisted)
    sign_up_team = SignUpTeam.where(teams_id: teams_id).first
    sign_up_team.is_waitlisted=is_waitlisted
    sign_up_team.save
    return sign_up_team
  end
end