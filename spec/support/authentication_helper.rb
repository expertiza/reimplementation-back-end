# spec/support/authentication_helper.rb

module AuthenticationHelper
  def login_user(user, password = 'password')
    post '/login', params: { user_name: user.email, password: password }
    JSON.parse(response.body)['token']
  end
  def login_admin
    post '/login', params: { user_name: 'admin', password: 'password123' }
    JSON.parse(response.body)['token']
  end
  def authenticated_header(user = nil, password = 'password')
    token = user ? login_user(user, password) : login_admin
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  # Use the authentication helper in the request specs
  config.include AuthenticationHelper, type: :request
end