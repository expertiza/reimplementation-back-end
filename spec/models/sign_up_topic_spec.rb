require 'rails_helper'

RSpec.describe SignUpTopic, type: :model do
  it "requires presence of name" do
    expect(SignUpTopic.new).not_to be_valid
  end

  it "requries presence of max choosers" do
    expect(SignUpTopic.new).not_to be_valid
  end

  it "creates valid sign up topic" do
    expect(SignUpTopic.new(name: "temp", max_choosers: 10)).to be_valid
  end

  describe "model helper" do
    it "creates a model through helper" do
      new_record = SignUpTopic.create_topic("name", 1, "category", "topic_identifier", "description")
      expect(new_record).to be_valid
    end
  end
end
