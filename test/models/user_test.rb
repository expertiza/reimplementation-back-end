require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      username: "test_user",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # Test valid user
  test "should be valid" do
    assert @user.valid?
  end

  # Test username presence
  test "should not save without a username" do
    @user.username = nil
    assert_not @user.valid?
  end

  # Test email presence
  test "should not save without an email" do
    @user.email = nil
    assert_not @user.valid?
  end

  # Test password presence
  test "should not save without a password" do
    @user.password = nil
    assert_not @user.valid?
  end

  # Test email format
  test "should not allow invalid email" do
    invalid_emails = ["user@", "user.com", "user@com", "user@example"]
    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?, "#{email.inspect} should be invalid"
    end
  end

  # Test unique email
  test "should not allow duplicate email" do
    @user.save
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    assert_not duplicate_user.valid?
  end

  # Test password length
  test "password should be at least 6 characters long" do
    @user.password = @user.password_confirmation = "12345"
    assert_not @user.valid?
  end

  # Test associations (Assuming User has many posts and comments)
  test "should have many posts" do
    assert_respond_to @user, :posts
  end

  test "should have many comments" do
    assert_respond_to @user, :comments
  end

  # Test authentication (Assuming Devise or has_secure_password is used)
  test "should authenticate with valid password" do
    @user.save
    assert @user.authenticate("password123")
  end

  test "should not authenticate with invalid password" do
    @user.save
    assert_not @user.authenticate("wrongpassword")
  end
end

