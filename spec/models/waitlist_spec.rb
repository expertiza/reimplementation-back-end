require 'rails_helper'

RSpec.describe Waitlist, type: :model do
  let (:topic) {create(:signup_topic)}
  let (:team) {create(:signed_up_team, signup_topic: topic)}

  describe "Tests associations" do
    it "belongs to the sign up topic" do
      should belong_to(:signup_topic)
    end

    it "belongs to the signed up team" do
      should belong_to(:signed_up_team)
    end
  end

  describe "Test functionality" do
    it "Returns count of teams waitlisted for given topic" do
      # TODO: check count of waitlisted teams
    end

    it "Removes teams from waitlist" do
      # TODO: remove a team from waitlist
    end

    it "Add teams to waitlist" do
      # TODO: adds teams to waitlist.
      waitlist = Waitlist.new(signup_topic_id: topic["id"], signed_up_team_id: team["id"])
      expect(waitlist).to be_valid
    end

    it "Get waitlisted teams" do
      # TODO: return list of waitlisted teams.
    end
  end
end
