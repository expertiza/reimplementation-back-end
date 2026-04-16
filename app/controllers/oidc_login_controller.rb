class OidcLoginController < ApplicationController
  skip_before_action :authenticate_request!

  rescue_from OidcConfig::ProviderNotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  rescue_from OpenIDConnect::Discovery::DiscoveryFailed, Rack::OAuth2::Client::Error do |e|
    render json: { error: "Provider communication failed: #{e.message}" }, status: :bad_gateway
  end

  # GET /auth/providers
  def providers
    render json: OidcConfig.public_list
  end

  # POST /auth/client-select
  # This is a good candidate for rate limiting
  def client_select
    authorization_uri = OidcRequest.authorization_uri_for!(provider_key: params[:provider])

    render json: { redirect_uri: authorization_uri }
  end

  # POST /auth/callback
  def callback
    # Look up and consume the auth request
    oidc_request = OidcRequest.consume_recent_by_state!(params[:state])

    # Match to existing user by email
    email = oidc_request.verified_email_from_code!(provider_key: oidc_request.provider, code: params[:code])
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
end
