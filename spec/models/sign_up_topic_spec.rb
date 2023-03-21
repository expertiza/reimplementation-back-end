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

  describe "CRUD method tests" do
    it "creates record via helper method" do
      first_record = SignUpTopic.new(name: "temp", max_choosers: 10)
      first_record.category = "category"
      first_record.topic_identifier = "id"
      first_record.description = "desc"
      created_record = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      expect(created_record.name).to eq(first_record.name)
      expect(created_record.category).to eq(first_record.category)
      expect(created_record.max_choosers).to eq(first_record.max_choosers)
      expect(created_record.topic_identifier).to eq(first_record.topic_identifier)
      expect(created_record.description).to eq(first_record.description)
    end

    it "updates record via helper method" do
      original_record = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      updated_record = SignUpTopic.update_topic("temp", 20, "category2", "desc2")
      expect(updated_record.max_choosers).to eq(20)
      expect(updated_record.category).to eq("category2")
      expect(updated_record.description).to eq("desc2")
    end

    it "deletes record via name" do
      original_record = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      SignUpTopic.delete_topic("temp")
      deleted_record = SignUpTopic.where(name: "temp")
      expect(deleted_record.empty?)
    end

    it "checks formatting of records" do
      record = SignUpTopic.create_topic("temp", 10, "category", "id", "desc")
      formatted_value = record.format_for_display()
      expected_value = "id - temp"
      expect(formatted_value).to eq(expected_value)
    end
  end

end
