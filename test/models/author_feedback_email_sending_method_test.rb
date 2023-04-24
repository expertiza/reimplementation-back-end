# frozen_string_literal: true
# references to sut refer to the "system under test". This is the target class for the unit test

class AuthorFeedbackEmailSendingMethodTest < ActiveSupport::TestCase
  # verify the instance getters returns expected values after instantiating object
  test "getters" do
    sut = AuthorFeedbackEmailSendingMethod.new({test: 1}, 2, 4)
    assert_equal 1, sut.command[:test]
    assert_equal 2, sut.assignment
    assert_equal 4, sut.reviewed_object_id
  end
end
