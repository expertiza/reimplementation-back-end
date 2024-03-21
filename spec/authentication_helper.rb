module AuthenticationHelper
  def authenticate_user(user)
    post '/login', params: { user_name: user.name, password: 'password' }
    json_response = JSON.parse(response.body)
    json_response['token'] # Assuming the token is returned in the response body
  end
end
