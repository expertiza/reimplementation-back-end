# spec/support/authentication_helper.rb

module AuthenticationHelper
  def login_user(user, password)
    raise 'User is nil' if user.nil?

    # Login and get the token
    post '/login', params: { user_name: user.email, password: password }
    token = JSON.parse(response.body)['token']

    # Raise an error if the token is nil
    raise 'User could not be logged in' if token.nil?

    # Return the token
    token
  end

  def authenticated_header(user = nil, password = 'password123')
    token = login_user(user, password)
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  # Use the authentication helper in the request specs
  config.include AuthenticationHelper, type: :request
end