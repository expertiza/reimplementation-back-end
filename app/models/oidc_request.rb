class OidcRequest < ApplicationRecord
  # Raised for any authentication failure (missing claim, unverified email, no matching user).
  # The controller rescues this and returns a generic 401 to avoid leaking which check failed.
  class AuthenticationError < StandardError; end

  # How long a newly-created auth request is considered valid before being treated as stale.
  VALIDITY_WINDOW = 5.minutes

  # Probability (0.0–1.0) of triggering a stale-cleanup job on each successful create.
  # Amortizes cleanup cost without requiring a dedicated scheduler.
  CLEANUP_PROBABILITY = 0.10

  after_create :maybe_enqueue_stale_cleanup

  # Deletes all auth requests older than the validity window.
  # Called by CleanupStaleOidcRequestsJob; safe to invoke directly for manual cleanup.
  def self.delete_stale
    where("created_at <= ?", VALIDITY_WINDOW.ago).delete_all
  end

  # Atomically finds and destroys the request matching the given state to prevent
  # replay attacks. Only considers requests within the validity window.
  # Raises ActiveRecord::RecordNotFound if no matching recent request exists.
  def self.consume_recent_by_state!(state)
    transaction do
      request = where("created_at > ?", VALIDITY_WINDOW.ago).lock.find_by!(state: state)
      request.destroy!
      request
    end
  end

  # Starts an OIDC login for the given provider and username:
  #   - Performs provider discovery
  #   - Generates fresh state, nonce, and PKCE values
  #   - Persists an OidcRequest row so the callback can verify and consume it
  # Returns the authorization URL the frontend should redirect the user to.
  # PKCE is always sent; providers that don't support it will ignore the extra params.
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

  # Exchanges the authorization code for tokens and verifies the ID token:
  #   - Signature via provider JWKS
  #   - Issuer, audience (client_id), and nonce claims
  #   - email_verified claim must be explicitly true
  # Returns the user's email from the ID token claims.
  # Raises AuthenticationError if the email is unverified or missing.
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

    raise AuthenticationError, "Email not verified by provider" unless claims["email_verified"] == true

    email = claims["email"].to_s.strip
    raise AuthenticationError, "Email missing from provider response" if email.blank?

    email
  end

  # Verifies the OIDC callback and resolves it to a local user.
  # Matches on both the stored username and the verified email claim because
  # emails are not unique in Expertiza. Whitespace and case are normalized on
  # both sides to handle legacy data with inconsistent formatting.
  # Raises AuthenticationError if no matching user is found.
  def authenticate_user!(code:)
    email = verified_email_from_code!(provider_key: provider, code: code)
    raise AuthenticationError, "No email claim in ID token" if email.blank?
    raise AuthenticationError, "No username associated with this request" if username.blank?

    normalized_username = username.to_s.strip.downcase
    normalized_email = email.to_s.strip.downcase

    User.where(
      "LOWER(TRIM(name)) = ? AND LOWER(TRIM(email)) = ?",
      normalized_username, normalized_email
    ).first || raise(AuthenticationError, "No account found for #{username} with email #{email}")
  end

  # Internal: builds an OpenIDConnect::Client from provider config and discovery.
  # Used by both authorization_uri_for! and verified_email_from_code!.
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

  private

  # after_create callback. Probabilistically enqueues a cleanup job for stale rows.
  # Runs inline since it's non-blocking (just pushes to the job queue).
  def maybe_enqueue_stale_cleanup
    CleanupStaleOidcRequestsJob.perform_later if rand < CLEANUP_PROBABILITY
  end
end
