class OidcRequest < ApplicationRecord
  class AuthenticationError < StandardError; end

  scope :recent, ->(window = 5.minutes) { where("created_at > ?", window.ago) }

  # Atomically finds and deletes the request to prevent replay attacks
  def self.consume_recent_by_state!(state, window: 5.minutes)
    transaction do
      request = recent(window).lock.find_by!(state: state)
      request.destroy!
      request
    end
  end

  # Generates PKCE, state, and nonce — stores them for callback verification
  # PKCE is always sent; providers that don't support it will ignore the extra params
  def self.authorization_uri_for!(provider_key:, username:)
    provider = OidcConfig.find(provider_key)
    discovery = OpenIDConnect::Discovery::Provider::Config.discover!(provider["issuer"])
    client = new_client(provider, discovery: discovery)

    state = SecureRandom.hex(32)
    nonce = SecureRandom.hex(32)
    code_verifier = SecureRandom.urlsafe_base64(64, false)
    code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier), padding: false
    )

    create!(
      state: state,
      nonce: nonce,
      code_verifier: code_verifier,
      provider: provider_key,
      username: username
    )

    client.authorization_uri(
      scope: OidcConfig.scopes_for(provider),
      state: state,
      nonce: nonce,
      code_challenge: code_challenge,
      code_challenge_method: "S256"
    )
  end

  # Exchanges the authorization code for tokens, then verifies:
  #   - ID token signature via provider JWKS
  #   - Issuer, audience (client_id), and nonce claims
  #   - email_verified claim if the provider includes it
  def verified_email_from_code!(provider_key:, code:)
    provider = OidcConfig.find(provider_key)
    discovery = OpenIDConnect::Discovery::Provider::Config.discover!(provider["issuer"])
    client = self.class.new_client(provider, discovery: discovery)

    client.authorization_code = code
    access_token = client.access_token!(code_verifier: code_verifier)

    id_token = OpenIDConnect::ResponseObject::IdToken.decode(
      access_token.id_token,
      discovery.jwks
    )
    id_token.verify!(
      issuer: discovery.issuer,
      client_id: provider["client_id"],
      nonce: nonce
    )

    claims = id_token.raw_attributes

    if claims.key?("email_verified") && claims["email_verified"] != true
      raise AuthenticationError, "Email not verified by provider"
    end

    claims["email"]
  end

  # Matches on both username from input and email from id_token because emails are not unique
  def authenticate_user!(code:)
    email = verified_email_from_code!(provider_key: provider, code: code)
    User.find_by(name: username, email: email) ||
      raise(AuthenticationError, "No account found for #{username} with email #{email}")
  end

  # Internal: builds an OpenIDConnect::Client from provider config and discovery
  def self.new_client(provider, discovery:)
    OpenIDConnect::Client.new(
      identifier: provider["client_id"],
      secret: provider["client_secret"],
      redirect_uri: provider["redirect_uri"],
      authorization_endpoint: discovery.authorization_endpoint,
      token_endpoint: discovery.token_endpoint,
      userinfo_endpoint: discovery.userinfo_endpoint
    )
  end
end