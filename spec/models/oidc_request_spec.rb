require 'rails_helper'

RSpec.describe OidcRequest, type: :model do
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

  describe '.consume_recent_by_state!' do
    let!(:recent_request) do
      OidcRequest.create!(
        state: 'recent-state',
        nonce: 'nonce',
        code_verifier: 'verifier',
        provider: 'google-ncsu'
      )
    end

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
      expect(described_class.find_by(id: recent_request.id)).to be_present
    end

    it 'supports a custom recency window' do
      recent_request.update_columns(created_at: 10.minutes.ago)

      consumed = described_class.consume_recent_by_state!('recent-state', window: 15.minutes)

      expect(consumed.id).to eq(recent_request.id)
      expect(described_class.find_by(id: recent_request.id)).to be_nil
    end
  end

  describe '.authorization_uri_for!' do
    before do
      allow(OidcConfig).to receive(:find).with('google-ncsu').and_return(provider)
    end

    it 'creates auth request and returns provider authorization URI' do
      allow(client).to receive(:authorization_uri)
        .with(hash_including(scope: %w[openid email profile], code_challenge_method: 'S256'))
        .and_return('https://accounts.google.com/o/oauth2/v2/auth?scope=openid+email+profile')

      expect do
        uri = described_class.authorization_uri_for!(provider_key: 'google-ncsu')
        expect(uri).to include('scope=openid+email+profile')
      end.to change(described_class, :count).by(1)
    end

    it 'uses default scopes when provider scopes are missing' do
      allow(OidcConfig).to receive(:find).with('google-ncsu')
        .and_return(provider.merge('scopes' => nil))
      allow(client).to receive(:authorization_uri)
        .with(hash_including(scope: %w[openid email profile], code_challenge_method: 'S256'))
        .and_return('https://accounts.google.com/o/oauth2/v2/auth?scope=openid+email+profile')

      described_class.authorization_uri_for!(provider_key: 'google-ncsu')
    end
  end

  describe '#verified_email_from_code!' do
    let(:oidc_request) do
      described_class.create!(
        state: 'state',
        nonce: 'nonce',
        code_verifier: 'verifier',
        provider: 'google-ncsu'
      )
    end

    let(:id_token_obj) do
      instance_double(
        OpenIDConnect::ResponseObject::IdToken,
        raw_attributes: { 'email' => 'oidcuser@ncsu.edu' }
      )
    end

    it 'exchanges code, verifies token and returns email' do
      allow(client).to receive(:authorization_code=).with('authorization-code')
      allow(client).to receive(:access_token!).with(code_verifier: 'verifier')
        .and_return(instance_double(OpenIDConnect::AccessToken, id_token: 'fake.id.token'))

      allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode)
        .with('fake.id.token', discovery.jwks)
        .and_return(id_token_obj)
      allow(id_token_obj).to receive(:verify!).with(
        issuer: 'https://accounts.google.com',
        client_id: 'test-client-id',
        nonce: 'nonce'
      )

      email = oidc_request.verified_email_from_code!(provider: provider, code: 'authorization-code')
      expect(email).to eq('oidcuser@ncsu.edu')
    end
  end

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