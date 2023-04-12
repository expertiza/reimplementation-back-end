require 'rails_helper'

RSpec.describe Waitlist, type: :model do
  describe "This tests associations" do
    it "belongs to the sign up topic" do
      should belong_to(:signup_topic)
    end

    it "belongs to the signed up team" do
      should belong_to(:signed_up_team)
    end
  end
end
