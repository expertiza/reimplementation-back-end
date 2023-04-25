require 'rails_helper'

RSpec.describe SignedUpTeam, type: :model do
  let (:topic) {create(:signup_topic)}
  let (:team) {create(:team)}
  let (:signed_up_team) {create(:signed_up_team, team:team, signup_topic:topic)}  
  

  describe "Test Associations" do
    it "belongs to the sign up topic" do
      should belong_to(:signup_topic)
    end

    it "belongs to the signed up team" do
      should belong_to(:team)
    end
  end

  describe "Test Functionality" do
    it "Returns the team participants for a signed_up_topic" do
      expect(signed_up_team.get_team_participants()).to eq(true)
    end

    it "Signs up a team for the topic if the topic is available and checks if the record exists in the database" do
      expect(SignedUpTeam.all.count). to eq(0)
      expect(SignedUpTeam.create_signed_up_team(topic["id"],team["id"])).to eq(true)
      expect(SignedUpTeam.all.count). to eq(1)      
    end

    it "Waitlists a team for the topic if the topic is not available and checks if the record exists in the database" do
      expect(SignedUpTeam.create_signed_up_team(topic["id"], team["id"])).to be true
      
      expect(Waitlist.count_waitlisted_teams(topic["id"])).to eq(0)
      
      team2 = Team.create
      expect(SignedUpTeam.create_signed_up_team(topic["id"], team2["id"])).to be true

      expect(Waitlist.count_waitlisted_teams(topic["id"])).to eq(1)
    end

    it 'Creates a signed up team if the topic is available and checks the count increment in the database' do
      expect { SignedUpTeam.create_signed_up_team(topic['id'], team['id']) }.to change(SignedUpTeam, :count).by(1)
    end

    it "Deletes the signed_up_team for the topic assigned and checks if the record exists in the database" do
      expect(SignedUpTeam.delete_signed_up_team(signed_up_team["id"])).to eq(true)
      expect(SignedUpTeam.exists?(signed_up_team['id'])).to be false
    end

    it 'Deletes the signed up team for a topic and delegates any required changes and checks the count decrement in the database' do
      expect(signed_up_team).to be_valid
      expect { SignedUpTeam.delete_signed_up_team(signed_up_team["id"]) }.to change(SignedUpTeam, :count).by(-1)
    end
    
  end
end
