# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OidcConfig, type: :model do
  before do
    described_class.reload!
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  after do
    described_class.reload!
  end

  describe '.providers' do
    it 'loads providers from YAML and evaluates ERB env vars' do
      original_client_id = ENV['GOOG_CLIENT_ID']
      original_client_secret = ENV['GOOG_CLIENT_SECRET']
      begin
        ENV['GOOG_CLIENT_ID'] = 'client-id-from-env'
        ENV['GOOG_CLIENT_SECRET'] = 'client-secret-from-env'

        yaml = <<~YAML
          providers:
            google-ncsu:
              display_name: Google NCSU
              issuer: https://accounts.google.com
              client_id: <%= ENV['GOOG_CLIENT_ID'] %>
              client_secret: <%= ENV['GOOG_CLIENT_SECRET'] %>
              redirect_uri: http://localhost:3000/auth/callback
              scopes: openid email profile
        YAML

        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(described_class::CONFIG_FILE).and_return(yaml)

        providers = described_class.providers

        expect(providers.keys).to eq(['google-ncsu'])
        expect(providers['google-ncsu']['client_id']).to eq('client-id-from-env')
        expect(providers['google-ncsu']['client_secret']).to eq('client-secret-from-env')
        expect(providers).to be_frozen
        expect(providers['google-ncsu']).to be_frozen
      ensure
        ENV['GOOG_CLIENT_ID'] = original_client_id
        ENV['GOOG_CLIENT_SECRET'] = original_client_secret
      end
    end

    it 'memoizes results until reload! is called' do
      first_yaml = <<~YAML
        providers:
          first:
            display_name: First
            issuer: https://issuer.example.com
            client_id: id-1
            client_secret: secret-1
            redirect_uri: http://localhost:3000/auth/callback
            scopes: openid email profile
      YAML

      second_yaml = <<~YAML
        providers:
          second:
            display_name: Second
            issuer: https://issuer-2.example.com
            client_id: id-2
            client_secret: secret-2
            redirect_uri: http://localhost:3000/auth/callback
            scopes: openid email profile
      YAML

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(described_class::CONFIG_FILE).and_return(first_yaml)

      expect(described_class.providers.keys).to eq(['first'])

      allow(File).to receive(:read).with(described_class::CONFIG_FILE).and_return(second_yaml)
      expect(described_class.providers.keys).to eq(['first'])

      described_class.reload!
      expect(described_class.providers.keys).to eq(['second'])
    end

    it 'skips invalid providers and warns for missing keys or invalid formats' do
      yaml = <<~YAML
        providers:
          valid:
            display_name: Valid
            issuer: https://issuer.example.com
            client_id: id
            client_secret: secret
            redirect_uri: http://localhost:3000/auth/callback
            scopes: openid email profile
          no_scopes:
            display_name: No Scopes
            issuer: https://issuer.example.com
            client_id: id
            client_secret: secret
            redirect_uri: http://localhost:3000/auth/callback
          missing_secret:
            display_name: Missing Secret
            issuer: https://issuer.example.com
            client_id: id
            redirect_uri: http://localhost:3000/auth/callback
            scopes: openid email profile
          malformed: hello
      YAML

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(described_class::CONFIG_FILE).and_return(yaml)

      providers = described_class.providers

      expect(providers.keys).to contain_exactly('valid', 'no_scopes')
      expect(Rails.logger).to have_received(:warn).with(/missing_secret.*missing client_secret/)
      expect(Rails.logger).to have_received(:warn).with(/malformed.*invalid config format/)
    end

    it 'returns an empty hash when YAML has no providers map' do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(described_class::CONFIG_FILE).and_return('[]')

      expect(described_class.providers).to eq({})
      expect(described_class.providers).to be_frozen
    end

    it 'supports YAML aliases in provider definitions' do
      yaml = <<~YAML
        providers:
          google:
            &base
            display_name: Google
            issuer: https://accounts.google.com
            client_id: id
            client_secret: secret
            redirect_uri: http://localhost:3000/auth/callback
            scopes: openid email profile
          google-copy:
            <<: *base
            display_name: Google Copy
      YAML

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(described_class::CONFIG_FILE).and_return(yaml)

      providers = described_class.providers

      expect(providers.keys).to contain_exactly('google', 'google-copy')
      expect(providers['google-copy']['issuer']).to eq('https://accounts.google.com')
    end

    it 'returns an empty hash and logs an error for malformed YAML' do
      malformed_yaml = "providers:\n  bad: [unterminated"

      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(described_class::CONFIG_FILE).and_return(malformed_yaml)

      expect(described_class.providers).to eq({})
      expect(Rails.logger).to have_received(:error).with(/OIDC config load failed:/)
    end
  end

  describe '.find' do
    it 'returns a provider config by key' do
      allow(described_class).to receive(:providers).and_return(
        'google-ncsu' => {
          'display_name' => 'Google NCSU',
          'issuer' => 'https://accounts.google.com',
          'client_id' => 'id',
          'client_secret' => 'secret',
          'redirect_uri' => 'http://localhost:3000/auth/callback',
          'scopes' => 'openid email profile'
        }
      )

      expect(described_class.find('google-ncsu')['display_name']).to eq('Google NCSU')
    end

    it 'raises ProviderNotFound for unknown provider keys' do
      allow(described_class).to receive(:providers).and_return({})

      expect { described_class.find('unknown') }
        .to raise_error(OidcConfig::ProviderNotFound, 'Unknown OIDC provider: unknown')
    end
  end

  describe '.public_list' do
    it 'returns only id and name for each provider' do
      allow(described_class).to receive(:providers).and_return(
        'google-ncsu' => {
          'display_name' => 'Google NCSU',
          'issuer' => 'https://accounts.google.com',
          'client_id' => 'id',
          'client_secret' => 'secret',
          'redirect_uri' => 'http://localhost:3000/auth/callback',
          'scopes' => 'openid email profile'
        }
      )

      expect(described_class.public_list).to eq([{ id: 'google-ncsu', name: 'Google NCSU' }])
    end
  end

  describe '.scopes_for' do
    it 'parses whitespace-delimited scope strings' do
      provider = { 'scopes' => 'openid email profile custom' }

      expect(described_class.scopes_for(provider)).to eq(%i[openid email profile custom])
    end

    it 'parses comma-delimited scope strings' do
      provider = { 'scopes' => 'openid,email,profile' }

      expect(described_class.scopes_for(provider)).to eq(%i[openid email profile])
    end

    it 'parses array scopes and stringifies symbols' do
      provider = { 'scopes' => [:openid, 'email', 'profile'] }

      expect(described_class.scopes_for(provider)).to eq(%i[openid email profile])
    end

    it 'falls back to default scopes when missing' do
      provider = { 'scopes' => nil }

      expect(described_class.scopes_for(provider)).to eq(%i[openid email profile])
    end
  end
end
