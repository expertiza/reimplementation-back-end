class OidcRequest < ApplicationRecord
  VALIDITY_WINDOW = 5.minutes
  CLEANUP_PROBABILITY = 0.10

  after_create :maybe_cleanup_stale

  scope :recent, ->(window = VALIDITY_WINDOW) { where("created_at > ?", window.ago) }
  scope :stale,  ->(window = VALIDITY_WINDOW) { where("created_at <= ?", window.ago) }
  private_class_method :recent, :stale

  def self.delete_stale(window: VALIDITY_WINDOW)
    stale(window).delete_all
  end

  def stale?(window = VALIDITY_WINDOW)
    created_at <= window.ago
  end

  def self.consume_recent_by_state!(state, window: VALIDITY_WINDOW)
    was_stale = false
    request   = nil

    transaction do
      request   = lock.find_by!(state: state)
      was_stale = request.stale?(window)
      request.destroy!
    end

    raise ActiveRecord::RecordNotFound if was_stale

    request
  end

  def self.authorization_uri_for!(provider_key:)
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
      provider: provider_key
    )

    client.authorization_uri(
      scope: OidcConfig.scopes_for(provider),
      state: state,
      nonce: nonce,
      code_challenge: code_challenge,
      code_challenge_method: "S256"
    )
  end

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

    id_token.raw_attributes["email"]
  end

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

  def maybe_cleanup_stale
    CleanupStaleOidcRequestsJob.perform_later if rand < CLEANUP_PROBABILITY
  end
end