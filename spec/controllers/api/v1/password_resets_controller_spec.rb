require 'rails_helper'

RSpec.describe PasswordResetsController, type: :controller do
  let(:user) { create(:password_reset_user) }
  let(:valid_password_params) { { user: { password: 'newpassword123', password_confirmation: 'newpassword123' } } }
  let(:invalid_password_params) { { user: { password: 'short', password_confirmation: 'short' } } }

  describe 'PasswordResetsController' do
    describe '#create' do
      context 'when the email exists' do
        before do
          allow(UserMailer).to receive_message_chain(:password_reset_email, :deliver_later)
          post :create, params: { email: user.email }
        end

        it 'sends a password reset email with a token accepted by User.find_by_token_for' do
          expect(UserMailer).to have_received(:password_reset_email) do |received_user, token|
            expect(received_user).to eq(user)
            expect(User.find_by_token_for(:password_reset, token)).to eq(user)
          end
        end

        it 'returns a success message' do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['message']).to eq(I18n.t('password_reset.email_sent'))
        end
      end

      context 'when the email does not exist' do
        before do
          post :create, params: { email: 'nonexistent@example.com' }
        end

        it 'returns an email if exists message' do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['message']).to eq(I18n.t('password_reset.email_sent'))
        end
      end
    end

    describe '#update' do
      context 'when the token is valid' do
        before do
          token = user.generate_token_for(:password_reset)
          put :update, params: { token: token }.merge(valid_password_params)
        end

        it 'updates the password' do
          old_password_hash = user.password_digest
          user.reload
          expect(user.authenticate('newpassword123')).to be_truthy
          expect(user.password_digest).not_to eq(old_password_hash)
        end

        it 'returns a success message' do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['message']).to eq(I18n.t('password_reset.updated'))
        end
      end

      context 'when the token is invalid or expired' do
        before do
          put :update, params: { token: 'invalidtoken' }.merge(valid_password_params)
        end

        it 'returns an error message' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('password_reset.errors.token_expired'))
        end
      end

      context 'when the password is invalid' do
        before do
          token = user.generate_token_for(:password_reset)
          put :update, params: { token: token }.merge(invalid_password_params)
        end

        it 'returns validation errors' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include(I18n.t('user.errors.password_short'))
        end
      end

      context 'when the token has expired' do
        before do
          token = user.generate_token_for(:password_reset)
          travel_to Time.current + 16.minutes do
            put :update, params: { token: token }.merge(valid_password_params)
          end
        end

        it 'returns invalid token' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq(I18n.t('password_reset.errors.token_expired'))
        end
      end
    end
  end
end