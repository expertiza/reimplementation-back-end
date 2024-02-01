require 'json_web_token'

module AuthenticationHelper

  def generate_auth_token(user)

    # Implement token generation logic here (e.g., JWT.encode or token creation methods)
    # This method should return the generated token.

    # db_user = User.find_by(name: user.name)
    db_user = User.find(user.id)
    if user && (db_user.password_digest).eql?(user.password_digest)
      payload = { id: user.id, name: user.name, full_name: user.full_name, role: user.role.name,
                  institution_id: user.institution_id }
      token = JsonWebToken.encode(payload, 24.hours.from_now)
      return token
    else
      return "no_token"
    end
  end

end