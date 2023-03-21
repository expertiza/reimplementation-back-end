class SignUpTeam < ApplicationRecord
  belongs_to :sign_up_topic counter_cache:true
  belongs_to :team
  
  validates :is_waitlisted, presence: true 

  # Get participants in the team signed up for the given topic.
  def self.find_team_participants()
    return team.get_team_participants()
  end

  def self.release_topics()
    # TODO: Update waitlist and release topics.
  end

  #Create a signUp team with the given parameters topic_id and is_waitlisted 
  def create_sign_up_team(is_waitlisted, topic_id)
    sign_up_topic = SignUpTeam.where(id: topic_id).first

    if sign_up_topic.find_if_topic_available() == false
      return

    sign_up_team = SignUpTeam.new
    sign_up_team.is_waitlisted=is_waitlisted
    sign_up_team.topic_id=topic_id
    sign_up_team.save
  end

  #When a team sign up for a topic and they want to opt out from that topic
  #this function is called to destroy that record
  def delete_sign_up_team(id)
    sign_up_team = SignUpTeam.where(id: id)
    sign_up_team.destroy
  end

  #Update the sign up team for a topic and update the records.
  def update_sign_up_team(id)
    #TODO: This can be done after Team model is built.
  end
end