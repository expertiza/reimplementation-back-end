require 'rails_helper'

RSpec.describe SignupTopic, type: :model do

  describe "Test Associations" do
    it "belongs to the assignment" do
      should belong_to(:assignment)
    end

    it "has many signed up teams" do
      should have_many(:signed_up_teams)
    end
  end

  describe "Test Functionality" do
    it "Returns the team participants of signed_up_team for topic" do

    end

    it "Updates the attributes of the sign up topic" do

    end

    it "Returns number of available slots for teams to sign up for the topic" do

    end

    describe "Returns number of filled slots for the topic" do
      it "Returns 0 if no teams signed up for the topic" do

      end

      it "Returns 1 if there is one signed up team for the topic" do

      end
    end

    it "Method used to release team from the topic" do

    end

    it "Method used to validate if the topic is assigned to signed up team" do

    end

    it "Returns whether the topic is available" do

    end

    it "Returns all the signed up teams for the topic" do

    end

    it "Returns JSON object that holds the signup topic data" do

    end

    it "Destroy the topic and delegates any required changes" do

    end

  end
end
