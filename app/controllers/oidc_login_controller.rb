class OidcLoginController < ApplicationController
  skip_before_action :authenticate_request!

  rescue_from OidcConfig::ProviderNotFound do |e|
    render_error e.message, status: :not_found
  end

  rescue_from OpenIDConnect::Discovery::DiscoveryFailed, Rack::OAuth2::Client::Error do |e|
    render_error "Provider communication failed: #{e.message}", status: :bad_gateway
  end

  rescue_from ActionController::ParameterMissing do |e|
    render_error e.message, status: :bad_request
  end

  # GET /auth/providers
  # Returns only public info (id, name) — no secrets or endpoints
  def providers
    render json: OidcConfig.public_list
  end

  # POST /auth/client-select
  # Username is required because emails are not unique
  # This is a good candidate for rate limiting
  def client_select
    provider = params.require(:provider)
    username = params.require(:username)

    authorization_uri = OidcRequest.authorization_uri_for!(
      provider_key: provider,
      username: username
    )
    render json: { redirect_uri: authorization_uri }
  end

  # POST /auth/callback
  # Returns a generic error for all failure modes to avoid leaking
  # whether the state, user, or token verification was the cause
  def callback
    state = params.require(:state)
    code = params.require(:code)

    oidc_request = OidcRequest.consume_recent_by_state!(state)
    user = oidc_request.authenticate_user!(code: code)
    render json: { token: user.generate_jwt }, status: :ok
  rescue ActiveRecord::RecordNotFound, OidcRequest::AuthenticationError,
    OpenIDConnect::ResponseObject::IdToken::InvalidToken
    render_error "Authentication failed", status: :unauthorized
  end

  private

  def render_error(message, status:)
    render json: { error: message }, status: status
  end
end