# spec/support/authentication_helper.rb

module AuthenticationHelper
  def login_user(user, password = 'password')
    post '/login', params: { user_name: user.email, password: password }
    JSON.parse(response.body)['token']
  end

  def login_admin
    # There should always be an admin in the seeded database, so if there aren't
    # any users, something has gone wrong
    if User.count.zero?
      raise 'No users found'
    end
    
    # Lookup admin
    admin_user = User.find_by(role_id: 1)
    if admin_user.nil?
      raise 'Admin user not found'
    end
    login_user(admin_user, 'password123')
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