# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#generate_jwt' do
    it 'encodes the user attributes into a jwt' do
      user = create(
        :user,
        name: 'jdoe',
        email: 'jdoe@example.com',
        full_name: 'John Doe'
      )
      expiry = 2.hours.from_now

      token = user.generate_jwt(expiry)
      payload = JsonWebToken.decode(token)

      # Aligns with frontend expectations
      expect(payload[:id]).to eq(user.id)
      expect(payload[:name]).to eq(user.name)
      expect(payload[:full_name]).to eq(user.full_name)
      expect(payload[:role]).to eq(user.role.name)
      expect(payload[:institution_id]).to eq(user.institution.id)
      expect(payload[:exp]).to eq(expiry.to_i)
    end
    it 'defaults to 24 hour expiry' do
      user = create(:user)
      token = user.generate_jwt
      payload = JsonWebToken.decode(token)

      expect(payload[:exp]).to be_within(5).of(24.hours.from_now.to_i)
    end
    it 'raises an error when the token signature is invalid' do
      user = create(:user)
      token = user.generate_jwt
      tampered_token = token.chop

      expect { JsonWebToken.decode(tampered_token) }.to raise_error(JWT::DecodeError)
    end
  end
end
