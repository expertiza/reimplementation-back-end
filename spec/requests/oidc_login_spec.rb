# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe OidcLoginController, type: :request do
  before(:each) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: "Test Institution")
  end

  let(:provider_cfg) do
    {
      "display_name"  => "Google NCSU",
      "issuer"        => "https://accounts.google.com",
      "client_id"     => "test-client-id",
      "client_secret" => "test-client-secret",
      "redirect_uri"  => "http://localhost:3000/auth/callback",
      "scopes"        => "openid email profile"
    }
  end

  def stub_provider_config(provider_key = "google-ncsu")
    allow(OidcConfig).to receive(:find).with(provider_key).and_return(provider_cfg)
  end

  def stub_discovery
    discovery = instance_double(
      OpenIDConnect::Discovery::Provider::Config::Response,
      authorization_endpoint: "https://accounts.google.com/o/oauth2/v2/auth",
      token_endpoint:         "https://oauth2.googleapis.com/token",
      userinfo_endpoint:      "https://openidconnect.googleapis.com/v1/userinfo",
      issuer:                 "https://accounts.google.com",
      jwks:                   instance_double(JSON::JWK::Set)
    )
    allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
                                                           .with("https://accounts.google.com").and_return(discovery)
    discovery
  end

  def stub_token_exchange(email:)
    fake_access_token = instance_double(OpenIDConnect::AccessToken, id_token: "fake.id.token")
    allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!).and_return(fake_access_token)

    id_token_obj = instance_double(
      OpenIDConnect::ResponseObject::IdToken,
      raw_attributes: { "email" => email }
    )
    allow(id_token_obj).to receive(:verify!).and_return(true)
    allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode).and_return(id_token_obj)
  end

  def create_oidc_request(state:, provider: "google-ncsu")
    OidcRequest.create!(
      state:         state,
      nonce:         "nonce-#{state}",
      code_verifier: "verifier-#{state}",
      provider:      provider
    )
  end

  # ─── GET /auth/providers ─────────────────────────────────────────────

  path '/auth/providers' do
    get 'List available OIDC providers' do
      tags 'OIDC Authentication'
      produces 'application/json'
      security []
      description 'Returns the list of configured OIDC identity providers that the front end can offer to users.'

      response '200', 'list of providers' do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id:   { type: :string, example: 'google-ncsu' },
                   name: { type: :string, example: 'Google NCSU' }
                 },
                 required: %w[id name]
               }

        before do
          allow(OidcConfig).to receive(:public_list).and_return([
                                                                  { id: "google-ncsu", name: "Google NCSU" }
                                                                ])
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json).to be_an(Array)
          expect(json.first).to include("id", "name")
        end
      end
    end
  end

  # ─── POST /auth/client-select ───────────────────────────────────────

  path '/auth/client-select' do
    post 'Initiate OIDC login for a chosen provider' do
      tags 'OIDC Authentication'
      consumes 'application/json'
      produces 'application/json'
      security []
      description <<~DESC
        Accepts a provider key, performs OIDC discovery, generates PKCE and state parameters,
        persists an OidcRequest for later verification, and returns the provider's authorization URL
        that the front end should redirect the user to.
      DESC

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          provider: { type: :string, example: 'google-ncsu', description: 'Key identifying the OIDC provider' }
        },
        required: %w[provider]
      }

      response '200', 'authorization redirect URI' do
        schema type: :object,
               properties: {
                 redirect_uri: { type: :string, example: 'https://accounts.google.com/o/oauth2/v2/auth?client_id=...&scope=openid+email+profile&state=...&nonce=...' }
               },
               required: %w[redirect_uri]

        let(:body) { { provider: "google-ncsu" } }

        before do
          allow(OidcRequest).to receive(:authorization_uri_for!)
                                  .with(provider_key: "google-ncsu")
                                  .and_return("https://accounts.google.com/o/oauth2/v2/auth?scope=openid+email+profile")
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["redirect_uri"]).to be_present
        end
      end

      response '404', 'unknown OIDC provider' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Unknown OIDC provider: nonexistent' }
               },
               required: %w[error]

        let(:body) { { provider: "nonexistent" } }

        before do
          allow(OidcRequest).to receive(:authorization_uri_for!)
                                  .and_raise(OidcConfig::ProviderNotFound, "Unknown OIDC provider: nonexistent")
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["error"]).to match(/Unknown OIDC provider/)
        end
      end

      response '502', 'provider discovery failed' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Provider communication failed: ...' }
               },
               required: %w[error]

        let(:body) { { provider: "google-ncsu" } }

        before do
          allow(OidcRequest).to receive(:authorization_uri_for!)
                                  .and_raise(OpenIDConnect::Discovery::DiscoveryFailed.new("Connection refused"))
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["error"]).to match(/Provider communication failed/)
        end
      end
    end
  end

  # ─── POST /auth/callback ────────────────────────────────────────────

  path '/auth/callback' do
    post 'Exchange an OIDC authorization code for a session token' do
      tags 'OIDC Authentication'
      consumes 'application/json'
      produces 'application/json'
      security []
      description <<~DESC
        Called by the front end after the user is redirected back from the identity provider.
        Exchanges the authorization code for tokens, verifies the ID token, and returns
        a local JWT session token if the user's email matches an existing account.
      DESC

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          state: { type: :string, description: 'The state parameter returned by the identity provider' },
          code:  { type: :string, description: 'The authorization code returned by the identity provider' }
        },
        required: %w[state code]
      }

      # ── 200 — successful authentication ──

      response '200', 'authenticated user with session token' do
        schema type: :object,
               properties: {
                 token: { type: :string, description: 'JWT session token' }
               },
               required: %w[token]

        let(:user) do
          User.create!(
            name: "oidcuser", password: "password", role_id: @roles[:student].id,
            full_name: "OIDC User", email: "oidcuser@ncsu.edu", institution: @institution
          )
        end

        let(:oidc_request) { create_oidc_request(state: "valid-state") }
        let(:body) { { state: oidc_request.state, code: "authorization-code" } }

        before do
          user
          stub_provider_config
          stub_discovery
          stub_token_exchange(email: "oidcuser@ncsu.edu")
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["token"]).to be_present
        end
      end

      # ── 404 — no matching account or unknown provider ──

      response '404', 'no account found or unknown provider' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'No account found for unknown@example.com' }
               },
               required: %w[error]

        context 'when no user exists for the email' do
          let(:oidc_request) { create_oidc_request(state: "state-no-user") }
          let(:body) { { state: oidc_request.state, code: "authorization-code" } }

          before do
            stub_provider_config
            stub_discovery
            stub_token_exchange(email: "unknown@example.com")
          end

          run_test! do |response|
            json = JSON.parse(response.body)
            expect(json["error"]).to match(/No account found/)
          end
        end

        context 'when the stored provider no longer exists' do
          let(:oidc_request) { create_oidc_request(state: "state-missing-provider", provider: "deleted-provider") }
          let(:body) { { state: oidc_request.state, code: "authorization-code" } }

          before do
            allow(OidcConfig).to receive(:find).with("deleted-provider")
                                               .and_raise(OidcConfig::ProviderNotFound, "Unknown OIDC provider: deleted-provider")
          end

          run_test! do |response|
            json = JSON.parse(response.body)
            expect(json["error"]).to eq("Unknown OIDC provider: deleted-provider")
          end
        end
      end

      # ── 422 — invalid or expired state ──

      response '422', 'invalid or expired login request' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Invalid or expired login request' }
               },
               required: %w[error]

        let(:body) { { state: "nonexistent-state", code: "authorization-code" } }

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["error"]).to eq("Invalid or expired login request")
        end
      end

      # ── 401 — token verification failed ──

      response '401', 'token verification failed' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Token verification failed: invalid signature' }
               },
               required: %w[error]

        let(:oidc_request) { create_oidc_request(state: "state-bad-token") }
        let(:body) { { state: oidc_request.state, code: "authorization-code" } }

        before do
          stub_provider_config
          stub_discovery

          fake_access_token = instance_double(OpenIDConnect::AccessToken, id_token: "fake.id.token")
          allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!).and_return(fake_access_token)

          allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode)
                                                             .and_raise(OpenIDConnect::ResponseObject::IdToken::InvalidToken.new("invalid signature"))
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["error"]).to match(/Token verification failed/)
        end
      end

      # ── 502 — provider communication failed ──

      response '502', 'provider communication failed' do
        schema type: :object,
               properties: {
                 error: { type: :string, example: 'Provider communication failed: ...' }
               },
               required: %w[error]

        let(:oidc_request) { create_oidc_request(state: "state-discovery-fail") }
        let(:body) { { state: oidc_request.state, code: "authorization-code" } }

        before do
          stub_provider_config

          allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
                                                                 .and_raise(OpenIDConnect::Discovery::DiscoveryFailed.new("Connection refused"))
        end

        run_test! do |response|
          json = JSON.parse(response.body)
          expect(json["error"]).to match(/Provider communication failed/)
        end
      end
    end
  end
end