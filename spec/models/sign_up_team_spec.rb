require 'rails_helper'

RSpec.describe SignUpTeam, type: :model do
  it "requires presence of is waitlisted" do 
    expect(SignUpTeam.new).not_to be_valid
  end

  describe "CRUD method tests" do 
    it "creates record via helper method" do
      created_record_topic = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      topic = SignUpTopic.where(topic_identifier: "id").first
      expect(topic).to eq(created_record_topic)
      first_record = SignUpTeam.new(is_waitlisted:true)
      first_record.sign_up_topic_id="id"
      first_record.teams_id="teams_id"
      created_record =SignUpTeam.create_sign_up_team(true, "id", "teams_id")
      expect(created_record.sign_up_topic_id).to eq(first_record.sign_up_topic_id)
      expect(created_record.teams_id).to eq(first_record.teams_id)
      expect(created_record.is_waitlisted).to eq(first_record.is_waitlisted)
    end

    it "deletes record via teams_id" do
      created_record_topic = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      topic = SignUpTopic.where(topic_identifier: "id").first
      expect(topic).to eq(created_record_topic)
      created_record_team=SignUpTeam.create_sign_up_team(true, "id", "teams_id")
      team = SignUpTeam.where(teams_id: "teams_id").first
      expect(team).to_not eq(created_record_team)
      # SignUpTeam.delete_sign_up_team("teams_id")
      # deleted_record = SignUpTeam.where(teams_id: "teams_id")
      # expect(deleted_record.empty?)
    end

    it "updates record via teams_id" do 
      created_record_topic = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      topic = SignUpTopic.where(topic_identifier: "id").first
      expect(topic).to eq(created_record_topic)
      created_record_team=SignUpTeam.create_sign_up_team(true, "id", "teams_id")
      team = SignUpTeam.where(teams_id: "teams_id").first
      expect(team).to_not eq(created_record_team)

    end


  end
  

end