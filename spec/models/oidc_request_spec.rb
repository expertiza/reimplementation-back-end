require 'rails_helper'

RSpec.describe OidcRequest, type: :model do
  include RolesHelper

  let(:provider) do
    {
      'display_name' => 'Google NCSU',
      'issuer' => 'https://accounts.google.com',
      'client_id' => 'test-client-id',
      'client_secret' => 'test-client-secret',
      'redirect_uri' => 'http://localhost:3000/auth/callback',
      'scopes' => 'openid email profile'
    }
  end

  let(:discovery) do
    instance_double(
      OpenIDConnect::Discovery::Provider::Config::Response,
      authorization_endpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
      token_endpoint: 'https://oauth2.googleapis.com/token',
      userinfo_endpoint: 'https://openidconnect.googleapis.com/v1/userinfo',
      issuer: 'https://accounts.google.com',
      jwks: instance_double(JSON::JWK::Set)
    )
  end

  let(:client) { instance_double(OpenIDConnect::Client) }

  before do
    allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
                                                           .with('https://accounts.google.com').and_return(discovery)
    allow(OpenIDConnect::Client).to receive(:new).and_return(client)
  end

  # ─── Helpers ────────────────────────────────────────────────────────

  def create_request(state: 'state', nonce: 'nonce', verifier: 'verifier',
                     provider: 'google-ncsu', username: 'oidcuser')
    described_class.create!(
      state: state,
      nonce: nonce,
      code_verifier: verifier,
      provider: provider,
      username: username
    )
  end

  def stub_token_exchange(email:, email_verified: nil)
    allow(client).to receive(:authorization_code=)
    allow(client).to receive(:access_token!)
                       .and_return(instance_double(OpenIDConnect::AccessToken, id_token: 'fake.id.token'))

    claims = { 'email' => email }
    claims['email_verified'] = email_verified unless email_verified.nil?

    id_token_obj = instance_double(
      OpenIDConnect::ResponseObject::IdToken,
      raw_attributes: claims
    )
    allow(id_token_obj).to receive(:verify!)
    allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode).and_return(id_token_obj)
  end

  # ─── .consume_recent_by_state! ──────────────────────────────────────

  describe '.consume_recent_by_state!' do
    let!(:recent_request) { create_request(state: 'recent-state') }

    it 'returns and destroys a recent request matching state' do
      consumed = described_class.consume_recent_by_state!('recent-state')

      expect(consumed.id).to eq(recent_request.id)
      expect(described_class.find_by(id: recent_request.id)).to be_nil
    end

    it 'raises RecordNotFound for unknown state' do
      expect { described_class.consume_recent_by_state!('missing-state') }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises RecordNotFound for expired requests' do
      recent_request.update_columns(created_at: 10.minutes.ago)

      expect { described_class.consume_recent_by_state!('recent-state') }
        .to raise_error(ActiveRecord::RecordNotFound)
      # Expired row is not deleted — only consumed rows are destroyed
      expect(described_class.find_by(id: recent_request.id)).to be_present
    end

    it 'prevents replay by destroying the row on consumption' do
      described_class.consume_recent_by_state!('recent-state')

      expect { described_class.consume_recent_by_state!('recent-state') }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # ─── .delete_stale ──────────────────────────────────────────────────

  describe '.delete_stale' do
    it 'deletes rows older than the validity window and preserves fresh rows' do
      fresh = create_request(state: 'fresh')
      stale = create_request(state: 'stale')
      stale.update_columns(created_at: 10.minutes.ago)

      described_class.delete_stale

      expect(described_class.find_by(id: fresh.id)).to be_present
      expect(described_class.find_by(id: stale.id)).to be_nil
    end
  end

  # ─── after_create :maybe_enqueue_stale_cleanup ──────────────────────

  describe 'probabilistic cleanup on create' do
    it 'enqueues CleanupStaleOidcRequestsJob when rand falls under the threshold' do
      allow_any_instance_of(described_class).to receive(:rand).and_return(0.0)

      expect(CleanupStaleOidcRequestsJob).to receive(:perform_later)

      create_request(state: 'any')
    end

    it 'does not enqueue when rand falls above the threshold' do
      allow_any_instance_of(described_class).to receive(:rand).and_return(0.99)

      expect(CleanupStaleOidcRequestsJob).not_to receive(:perform_later)

      create_request(state: 'any')
    end
  end

  # ─── .authorization_uri_for! ────────────────────────────────────────

  describe '.authorization_uri_for!' do
    before do
      allow(OidcConfig).to receive(:find).with('google-ncsu').and_return(provider)
    end

    it 'creates auth request with username and returns provider authorization URI' do
      allow(client).to receive(:authorization_uri)
                         .with(hash_including(scope: %w[openid email profile], code_challenge_method: 'S256'))
                         .and_return('https://accounts.google.com/o/oauth2/v2/auth?scope=openid+email+profile')

      expect do
        uri = described_class.authorization_uri_for!(provider_key: 'google-ncsu', username: 'oidcuser')
        expect(uri).to include('scope=openid+email+profile')
      end.to change(described_class, :count).by(1)

      created = described_class.last
      expect(created.username).to eq('oidcuser')
      expect(created.provider).to eq('google-ncsu')
    end

    it 'uses default scopes when provider scopes are missing' do
      allow(OidcConfig).to receive(:find).with('google-ncsu')
                                         .and_return(provider.merge('scopes' => nil))
      allow(client).to receive(:authorization_uri)
                         .with(hash_including(scope: %w[openid email profile], code_challenge_method: 'S256'))
                         .and_return('https://accounts.google.com/o/oauth2/v2/auth?scope=openid+email+profile')

      described_class.authorization_uri_for!(provider_key: 'google-ncsu', username: 'oidcuser')
    end

    it 'raises when creating a request with a duplicate state' do
      create_request(state: 'duplicate-state')

      expect {
        create_request(state: 'duplicate-state', nonce: 'different-nonce')
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  # ─── #verified_email_from_code! ─────────────────────────────────────

  describe '#verified_email_from_code!' do
    before do
      allow(OidcConfig).to receive(:find).with('google-ncsu').and_return(provider)
    end

    let(:oidc_request) { create_request }

    it 'exchanges code, verifies token and returns email' do
      stub_token_exchange(email: 'oidcuser@ncsu.edu', email_verified: true)

      email = oidc_request.verified_email_from_code!(provider_key: 'google-ncsu', code: 'authorization-code')
      expect(email).to eq('oidcuser@ncsu.edu')
    end

    it 'returns email when email_verified is true' do
      stub_token_exchange(email: 'oidcuser@ncsu.edu', email_verified: true)

      email = oidc_request.verified_email_from_code!(provider_key: 'google-ncsu', code: 'authorization-code')
      expect(email).to eq('oidcuser@ncsu.edu')
    end

    it 'raises AuthenticationError when email_verified claim is absent' do
      stub_token_exchange(email: 'oidcuser@ncsu.edu')

      expect { oidc_request.verified_email_from_code!(provider_key: 'google-ncsu', code: 'authorization-code') }
        .to raise_error(OidcRequest::AuthenticationError, /Email not verified/)
    end

    it 'raises AuthenticationError when email_verified is false' do
      stub_token_exchange(email: 'oidcuser@ncsu.edu', email_verified: false)

      expect { oidc_request.verified_email_from_code!(provider_key: 'google-ncsu', code: 'authorization-code') }
        .to raise_error(OidcRequest::AuthenticationError, /Email not verified/)
    end
  end

  # ─── #authenticate_user! ────────────────────────────────────────────

  describe '#authenticate_user!' do
    before(:each) do
      @roles = create_roles_hierarchy
      @institution = Institution.first || Institution.create!(name: "Test Institution")
      allow(OidcConfig).to receive(:find).with('google-ncsu').and_return(provider)
    end

    let!(:user) do
      User.create!(
        name: "OidcUser", password: "password", role_id: @roles[:student].id,
        full_name: "OIDC User", email: "OidcUser@ncsu.edu", institution: @institution
      )
    end

    it 'matches user by username and email' do
      oidc_request = create_request(username: 'OidcUser')
      stub_token_exchange(email: 'OidcUser@ncsu.edu', email_verified: true)

      result = oidc_request.authenticate_user!(code: 'authorization-code')
      expect(result.id).to eq(user.id)
    end

    it 'matches user case-insensitively on username' do
      oidc_request = create_request(username: 'oidcuser')
      stub_token_exchange(email: 'OidcUser@ncsu.edu', email_verified: true)

      result = oidc_request.authenticate_user!(code: 'authorization-code')
      expect(result.id).to eq(user.id)
    end

    it 'matches user case-insensitively on email' do
      oidc_request = create_request(username: 'OidcUser')
      stub_token_exchange(email: 'oidcuser@ncsu.edu', email_verified: true)

      result = oidc_request.authenticate_user!(code: 'authorization-code')
      expect(result.id).to eq(user.id)
    end

    it 'matches user case-insensitively on both username and email' do
      oidc_request = create_request(username: 'OIDCUSER')
      stub_token_exchange(email: 'OIDCUSER@NCSU.EDU', email_verified: true)

      result = oidc_request.authenticate_user!(code: 'authorization-code')
      expect(result.id).to eq(user.id)
    end

    it 'raises AuthenticationError when email matches but username does not' do
      oidc_request = create_request(username: 'wronguser')
      stub_token_exchange(email: 'OidcUser@ncsu.edu', email_verified: true)

      expect { oidc_request.authenticate_user!(code: 'authorization-code') }
        .to raise_error(OidcRequest::AuthenticationError, /No account found/)
    end

    it 'raises AuthenticationError when username matches but email does not' do
      oidc_request = create_request(username: 'OidcUser')
      stub_token_exchange(email: 'different@example.com', email_verified: true)

      expect { oidc_request.authenticate_user!(code: 'authorization-code') }
        .to raise_error(OidcRequest::AuthenticationError, /No account found/)
    end

    it 'raises AuthenticationError when neither username nor email match' do
      oidc_request = create_request(username: 'nobody')
      stub_token_exchange(email: 'nobody@example.com', email_verified: true)

      expect { oidc_request.authenticate_user!(code: 'authorization-code') }
        .to raise_error(OidcRequest::AuthenticationError, /No account found/)
    end
  end

  # ─── .new_client ────────────────────────────────────────────────────

  describe '.new_client' do
    it 'builds an OpenIDConnect::Client with provider credentials and discovery endpoints' do
      expect(OpenIDConnect::Client).to receive(:new).with(
        identifier: 'test-client-id',
        secret: 'test-client-secret',
        redirect_uri: 'http://localhost:3000/auth/callback',
        authorization_endpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
        token_endpoint: 'https://oauth2.googleapis.com/token',
        userinfo_endpoint: 'https://openidconnect.googleapis.com/v1/userinfo'
      ).and_return(client)

      result = described_class.new_client(provider, discovery: discovery)
      expect(result).to eq(client)
    end
  end
end