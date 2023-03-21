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

  describe "test helper methods" do
    it "create record via helper method" do
      temp = SignUpTopic.new(name: "temp", max_choosers: 10)
      temp.category = "category"
      temp.topic_identifier = "id"
      temp.description = "desc"
      temp2 = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      expect(temp2.name).to eq(temp.name)
      expect(temp2.category).to eq(temp.category)
      expect(temp2.max_choosers).to eq(temp.max_choosers)
      expect(temp2.topic_identifier).to eq(temp.topic_identifier)
      expect(temp2.description).to eq(temp.description)
    end
  end

end
