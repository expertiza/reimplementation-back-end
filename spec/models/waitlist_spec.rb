require 'rails_helper'

RSpec.describe Waitlist, type: :model do
  let (:topic) {create(:signup_topic)}
  let (:waitlisted_team) {create(:signed_up_team, signup_topic: topic, is_waitlisted: true)}
  let (:non_waitlisted_team) {create(:signed_up_team, signup_topic: topic)}

  # These set of tests validate the methods available in waitlist with their expected behavior.
  describe "This tests functionality of the waitlist and" do
    it "checks basic validity of waitlisted team" do
      expect(waitlisted_team).to be_valid
    end

    # This test adds a waitlist entry and then calls the helper method to validate the count of teams currently in the waitlist for the given topic.
    it "returns count of teams waitlisted for given topic" do
      expect(waitlisted_team).to be_valid

      actual_count_for_topic = SignupTopic.count_waitlisted_teams(topic["id"])
      expected_count_for_topic = 1
      expect(actual_count_for_topic).to eq(expected_count_for_topic)
    end

    # This test adds a team to the waitlist and then queries for it to check for query response.
    it "gets the waitlisted teams" do
      expect(waitlisted_team).to be_valid

      teams = SignupTopic.get_waitlisted_teams(topic["id"])
      expect(teams).to include(waitlisted_team["id"])
    end

    # This test validates the selection of teams to be promoted from the waitlist.
    it "Promotes waitlisted teams" do
      expect(waitlisted_team).to be_valid

      actual_promoted_teams = SignupTopic.promote_teams_from_waitlist(topic["id"])

      expect(actual_promoted_teams).to include(waitlisted_team["id"])

      waitlist_count = SignupTopic.count_waitlisted_teams(topic["id"])
      expect(waitlist_count).to eq(0)
    end
  end

  # These set of tests validate the behavior of the waitlist in corner cases.
  describe "This tests error functionality of the waitlist and" do
    # This test checks if the count of the waitlist for a topic other than the one added is zero.
    it "checks if counts of topics for untouched topics is zero." do
      expect(waitlisted_team).to be_valid

      non_existent_topic = 2
      actual_count_for_topic = SignupTopic.count_waitlisted_teams(non_existent_topic)
      expected_count_for_topic = 0
      expect(actual_count_for_topic).to eq(expected_count_for_topic)
    end

    # This test validates that the response for a topic that does not have any waitlisted teams in it is valid.
    it "checks if waitlist for incorrect topics does not include invalid members" do
      expect(waitlisted_team).to be_valid

      non_existent_topic = 2
      teams = SignupTopic.get_waitlisted_teams(non_existent_topic)
      expect(teams).to_not include(waitlisted_team["id"])
      expect(teams).to_not include(non_waitlisted_team["id"])
    end

    # Test if promotion of a topic which does not have any waitlisted teams causes any issues.  
    it "checks if promotion of different topic does not modify other topic waitlist" do
      expect(waitlisted_team).to be_valid

      actual_promoted_teams = SignupTopic.promote_teams_from_waitlist(2)

      expect(actual_promoted_teams).to_not include(waitlisted_team["id"])

      waitlist_count = SignupTopic.count_waitlisted_teams(topic["id"])
      expect(waitlist_count).to eq(1)
    end
  end
end
