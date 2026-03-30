# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:postman_flow_mentor)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "should not save without required attributes" do
    user = User.new
    assert_not user.save, "Saved the user without required attributes"
  end
end
