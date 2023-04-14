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
      expect(signed_up_team.find_team_participants()).to eq(true)
    end

    it "Signs up a team for the topic" do
      expect(SignedUpTeam.create_signed_up_team(topic["id"],signed_up_team["id"])).to eq(true)
    end

    it "Deletes the signed_up_team for the topic assigned" do
      expect(SignedUpTeam.delete_signed_up_team(signed_up_team["id"])).to eq(true)
    end
  end
end
