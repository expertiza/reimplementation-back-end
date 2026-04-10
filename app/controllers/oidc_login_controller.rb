class OidcLoginController < ApplicationController
  skip_before_action :authenticate_request!

  # GET /auth/providers
  def providers
    render json: OidcConfig.public_list
  end

  # POST /auth/client-select
  def client_select
    provider = OidcConfig.find(params[:provider])
    client   = build_client(provider)

    # Generate state, nonce, and PKCE
    state         = SecureRandom.hex(32)
    nonce         = SecureRandom.hex(32)
    code_verifier = SecureRandom.urlsafe_base64(64)
    code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier), padding: false
    )

    # Store in DB for callback verification
    AuthRequest.create!(
      state:         state,
      nonce:         nonce,
      code_verifier: code_verifier,
      provider:      params[:provider]
    )

    # Build the authorization URL
    authorization_uri = client.authorization_uri(
      scope:                [:openid, :email, :profile],
      state:                state,
      nonce:                nonce,
      code_challenge:       code_challenge,
      code_challenge_method: "S256"
    )

    render json: { redirect_uri: authorization_uri }
  end

  # POST /auth/callback
  def callback
    # Look up and consume the auth request
    auth_request = AuthRequest
                     .where("created_at > ?", 5.minutes.ago)
                     .find_by!(state: params[:state])
    auth_request.destroy!

    provider = OidcConfig.find(auth_request.provider)
    client   = build_client(provider)

    # Exchange authorization code for tokens
    client.authorization_code = params[:code]
    access_token = client.access_token!(
      code_verifier: auth_request.code_verifier
    )

    # Decode and verify the ID token
    discovery = discover(provider)
    id_token  = OpenIDConnect::ResponseObject::IdToken.decode(
      access_token.id_token,
      discovery.jwks
    )
    id_token.verify!(
      issuer:    discovery.issuer,
      client_id: provider["client_id"],
      nonce:     auth_request.nonce
    )

    # Match to existing user by email
    email = id_token.raw_attributes["email"]
    user  = User.find_by(email: email)

    if user
      token = user.generate_jwt
      render json: { token: }, status: :ok
    else
      render json: { error: "No account found for #{email}" }, status: :not_found
    end

  rescue ActiveRecord::RecordNotFound
    render json: { error: "Invalid or expired login request" }, status: :unprocessable_entity
  rescue OpenIDConnect::ResponseObject::IdToken::InvalidToken => e
    render json: { error: "Token verification failed: #{e.message}" }, status: :unauthorized
  end

  private

  def build_client(provider)
    discovery = discover(provider)
    OpenIDConnect::Client.new(
      identifier:             provider["client_id"],
      secret:                 provider["client_secret"],
      redirect_uri:           provider["redirect_uri"],
      authorization_endpoint: discovery.authorization_endpoint,
      token_endpoint:         discovery.token_endpoint,
      userinfo_endpoint:      discovery.userinfo_endpoint
    )
  end

  def discover(provider)
    # Avoid duplicate discovery calls within the same request
    @discoveries ||= {}
    @discoveries[provider["issuer"]] ||=
      OpenIDConnect::Discovery::Provider::Config.discover!(provider["issuer"])
  end
end
