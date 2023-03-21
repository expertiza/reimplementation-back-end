class SignUpTeam < ApplicationRecord
  belongs_to :sign_up_topic counter_cache:true
  
  validates :is_waitlisted, presence: true 

  def create_sign_up_team(is_waitlisted,topic_id)
    sign_up_team = SignUpTeam.new
    sign_up_team.is_waitlisted=is_waitlisted
    sign_up_team.topic_id=topic_id 
    sign_up_team.save 
  end 

  def delete_sign_up_team(id)
    sign_up_team = SignUpTeam.where(id: id)
    sign_up_team.destroy
    end 

  def update_sign_up_team(id)
    #TODO: This can be done after Team model is built.
  end

end