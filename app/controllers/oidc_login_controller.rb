class OidcLoginController < ApplicationController
  skip_before_action :authenticate_request!

  rescue_from OidcConfig::ProviderNotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  # GET /auth/providers
  def providers
    render json: OidcConfig.public_list.to_json
  end

  # POST /auth/client-select
  def client_select
    authorization_uri = OidcRequest.authorization_uri_for!(provider_key: params[:provider])

    render json: { redirect_uri: authorization_uri }
  end

  # POST /auth/callback
  def callback
    # Look up and consume the auth request
    auth_request = OidcRequest.consume_recent_by_state!(params[:state])

    provider = OidcConfig.find(auth_request.provider)

    # Match to existing user by email
    email = auth_request.verified_email_from_code!(provider: provider, code: params[:code])
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
