require 'rails_helper'

RSpec.describe Api::V1::PasswordsController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_password_params) { { user: { password: 'newpassword123', password_confirmation: 'newpassword123' } } }
  let(:invalid_password_params) { { user: { password: 'short', password_confirmation: 'short' } } }

  describe 'PasswordsController' do
    describe '#create' do
      context 'when the email exists' do
        before do
          allow(UserMailer).to receive_message_chain(:send_password_reset_email, :deliver_later)
          post :create, params: { email: user.email }
        end

        it 'generates a password reset token' do
          user.reload
          expect(user.reset_password_token).to be_present
        end

        it 'sends a password reset email' do
          expect(UserMailer).to have_received(:send_password_reset_email).with(user)
        end

        it 'returns a success message' do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['message']).to eq("If the email exists, a reset link has been sent.")
        end
      end

      context 'when the email does not exist' do
        before do
          post :create, params: { email: 'nonexistent@example.com' }
        end

        it 'returns an error message' do
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['error']).to eq("No account is associated with the e-mail address: nonexistent@example.com. Please try again.")
        end
      end
    end

    describe '#update' do
      context 'when the token is valid' do
        before do
          user.generate_password_reset_token!
          put :update, params: { token: user.reset_password_token }.merge(valid_password_params)
        end

        it 'updates the password' do
          user.reload
          expect(user.authenticate('newpassword123')).to be_truthy
        end

        it 'clears the password reset token' do
          user.reload
          expect(user.reset_password_token).to be_nil
        end

        it 'returns a success message' do
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['message']).to eq("Password successfully updated.")
        end
      end

      context 'when the token is invalid or expired' do
        before do
          put :update, params: { token: 'invalidtoken' }.merge(valid_password_params)
        end

        it 'returns an error message' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['error']).to eq("Invalid or expired token.")
        end
      end

      context 'when the password is invalid' do
        before do
          user.generate_password_reset_token!
          put :update, params: { token: user.reset_password_token }.merge(invalid_password_params)
        end

        it 'returns validation errors' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)['errors']).to include("Password is too short (minimum is 8 characters)")
        end
      end
    end
  end
end