require 'rails_helper'

RSpec.describe SignUpTopic, type: :model do
  it "requires presence of name" do
    expect(SignUpTopic.new).not_to be_valid
  end
end
