class OidcLoginController < ApplicationController
  # OIDC login does not require an existing session — this is how users sign in.
  skip_before_action :authenticate_request!

  # Unknown provider keys from the frontend return 404 with the specific message.
  rescue_from OidcConfig::ProviderNotFound do |e|
    render_error e.message, status: :not_found
  end

  # IdP discovery or token endpoint unreachable — surface as 502 Bad Gateway
  # so the frontend can distinguish provider outages from user-facing errors.
  rescue_from OpenIDConnect::Discovery::DiscoveryFailed, Rack::OAuth2::Client::Error do |e|
    render_error "Provider communication failed: #{e.message}", status: :bad_gateway
  end

  # Missing required params (from params.require) return 400 with the param name.
  rescue_from ActionController::ParameterMissing do |e|
    render_error e.message, status: :bad_request
  end

  # GET /auth/providers
  # Returns the list of configured OIDC providers for the frontend dropdown.
  # Only public info (id, name) — no secrets or endpoint URLs.
  def providers
    render json: OidcConfig.public_list
  end

  # POST /auth/client-select
  # Initiates an OIDC login. The frontend calls this with the chosen provider
  # and the user's Expertiza username, and receives an authorization URL to
  # redirect the browser to. Username is required here because the IdP only
  # returns an email claim, and Expertiza emails are not unique across accounts.
  # Candidate for rate limiting — it creates a DB row and triggers provider discovery.
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
  # Completes an OIDC login after the IdP redirects the user back to the frontend.
  # Consumes the stored OidcRequest by state, verifies the ID token, matches a
  # local user, and issues a session JWT.
  # Returns a generic 401 "Authentication failed" for all verification or matching
  # failures to avoid leaking which check failed (state, token, user match, etc.).
  def callback
    state = params.require(:state)
    code = params.require(:code)

    oidc_request = OidcRequest.consume_recent_by_state!(state)
    user = oidc_request.authenticate_user!(code: code)
    render json: { token: user.generate_jwt }, status: :ok
  rescue ActiveRecord::RecordNotFound, OidcRequest::AuthenticationError,
    OpenIDConnect::ResponseObject::IdToken::InvalidToken,
    OidcConfig::ProviderNotFound
    render_error "Authentication failed", status: :unauthorized
  end

  private

  # Standardizes the JSON error response shape across all endpoints.
  def render_error(message, status:)
    render json: { error: message }, status: status
  end
end
