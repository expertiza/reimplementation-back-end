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

  describe "This tests functionality of the waitlist" do
    # Helper method to use add an entry to the waitlist table using the active records created by the sign up topic and signed up team factories.
    def add_entry_to_waitlist()
      waitlist = Waitlist.new(
        signup_topic_id: topic["id"], 
        signed_up_team_id: team["id"])
      waitlist.save
      return waitlist
    end
    
    # This test uses the factories to create a signed_up_team and signup_topic which then gets added to the 
    it "Add teams to waitlist" do
      expect(add_entry_to_waitlist()).to be_valid
    end

    # This test adds a waitlist entry and then calls the helper method to validate the count of teams currently in the waitlist for the given topic.
    it "Returns count of teams waitlisted for given topic" do
      expect(add_entry_to_waitlist()).to be_valid

      actual_count_for_topic = Waitlist.count_waitlisted_teams(topic["id"])
      expected_count_for_topic = 1
      expect(actual_count_for_topic).to eq(expected_count_for_topic)
    end

    it "Removes teams from waitlist" do
      expect(add_entry_to_waitlist()).to be_valid

      delete_count = Waitlist.remove_teams_from_waitlist(topic["id"], [team["id"]])

      expect(delete_count).to eq(1)
    end

    # This test adds a team to the waitlist and then queries for it to check for query response.
    it "Get waitlisted teams" do
      expect(add_entry_to_waitlist()).to be_valid

      teams = Waitlist.get_waitlisted_teams(topic["id"])
      expect(teams).to include(team["id"])
    end

    it "Promotes waitlisted teams" do
      expect(add_entry_to_waitlist()).to be_valid

      actual_promoted_teams = Waitlist.promote_teams_from_waitlist(topic["id"])

      expect(actual_promoted_teams).to include(team["id"])

      waitlist_count = Waitlist.count_waitlisted_teams(team["id"])
      expect(waitlist_count).to eq(0)
    end
  end
end
