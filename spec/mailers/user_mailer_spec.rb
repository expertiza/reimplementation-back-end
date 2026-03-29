# spec/mailers/user_mailer_spec.rb
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'send reset email' do
    let(:user) { create(:password_reset_user)}
    let(:token) { user.generate_token_for(:password_reset)}

    it 'sends email with token' do
      email = UserMailer.password_reset_email(user, token).deliver_now
      expect(email.from).to include('expertizamailer@gmail.com')
      expect(email.to).to include(user.email)
      expect(email.subject).to eq(I18n.t('password_reset.email_subject'))
      expect(email.body.encoded).to include('Expertiza password reset')
      expect(email.body.encoded).to include("?token=#{token}")
    end

    it 'builds reset link from configured frontend base URL' do
      # Verify FRONTEND_URL constant is properly configured (defaults from config/environments/test.rb)
      expect(FRONTEND_URL).to be_present
      expect(FRONTEND_URL).to match(%r{^https?://})

      email = UserMailer.password_reset_email(user, token).deliver_now
      expected_reset_url_pattern = %r{#{Regexp.escape(FRONTEND_URL)}/[a-z_/]+\?token=#{token}}
      expect(email.body.encoded).to match(expected_reset_url_pattern)
    end
  end
end
