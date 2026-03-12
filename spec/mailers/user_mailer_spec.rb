# spec/mailers/user_mailer_spec.rb
require 'rails_helper'

RSpec.describe UserMailer, type: :mailer do
  describe 'send reset email' do
    let(:user) { create(:password_reset_user)}
    let(:token) { user.generate_token_for(:password_reset)}
    let(:token_url) { UserMailer.new.send(:get_password_reset_url, token)}

    it 'sends email with token' do
      email = UserMailer.send_password_reset_email(user, token).deliver_now
      expect(email.from).to include('expertizamailer@gmail.com')
      expect(email.to).to include(user.email)
      expect(email.subject).to eq(I18n.t('password_reset.email_subject'))
      expect(email.body.encoded).to include('Expertiza password reset')
      expect(email.body.encoded).to include(token_url)
    end
  end
end

# describe UserMailer do
#   describe '#send_password_reset_email' do
#     let(:user) { create(:password_reset_user) }
#     let(:token) { user.generate_token_for(:password_reset) }
#
#     it 'sends email with correct content' do
#       email = UserMailer.send_password_reset_email(user, token)
#
#       expect(email.to).to include(user.email)
#       expect(email.subject).to eq('Password Reset Instructions')
#       expect(email.body.encoded).to include('reset your password')
#       expect(email.body.encoded).to include(token)
#     end
#   end
# end