# require 'rails_helper'

# RSpec.describe Api::V1::NotificationsController, type: :controller do
#   let(:admin) { create(:user, role: 'Admin') }
#   let(:student) { create(:user, role: 'Student') }
#   let(:notification) { create(:notification) }

#   describe 'GET #index' do
#     before { sign_in admin }

#     it 'returns notifications for the current user' do
#       get :index
#       expect(response).to have_http_status(:ok)
#       expect(json_response).to include(notification)
#     end

#     it 'denies access to unauthorized users' do
#       sign_out admin
#       sign_in student
#       get :index
#       expect(response).to have_http_status(:forbidden)
#     end
#   end

#   describe 'POST #create' do
#     context 'with valid attributes' do
#       it 'creates a new notification' do
#         expect {
#           post :create, params: { notification: attributes_for(:notification) }
#         }.to change(Notification, :count).by(1)
#       end
#     end

#     context 'with invalid attributes' do
#       it 'returns validation errors' do
#         post :create, params: { notification: { subject: '' } }
#         expect(response).to have_http_status(:unprocessable_entity)
#       end
#     end
#   end
# end


require 'swagger_helper'

RSpec.describe 'Notifications API', type: :request do
  path '/notifications' do
    get 'Retrieve all notifications' do
      tags 'Notifications'
      produces 'application/json'

      response '200', 'notifications retrieved' do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   subject: { type: :string },
                   description: { type: :string },
                   expiration_date: { type: :string, format: 'date' },
                   active_flag: { type: :boolean },
                   course_id: { type: :integer },
                   user_id: { type: :integer }
                 },
                 required: ['id', 'subject', 'expiration_date', 'active_flag', 'course_id', 'user_id']
               }
        run_test!
      end
    end
  end

  path '/notifications/{id}' do
    get 'Retrieve a specific notification' do
      tags 'Notifications'
      produces 'application/json'
      parameter name: :id, in: :path, type: :integer, description: 'Notification ID'

      response '200', 'notification found' do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 subject: { type: :string },
                 description: { type: :string },
                 expiration_date: { type: :string, format: 'date' },
                 active_flag: { type: :boolean },
                 course_id: { type: :integer },
                 user_id: { type: :integer }
               },
               required: ['id', 'subject', 'expiration_date', 'active_flag', 'course_id', 'user_id']
        let(:id) { Notification.create(subject: 'Test', description: 'Sample', expiration_date: '2024-12-31', active_flag: true, course_id: 1, user_id: 1).id }
        run_test!
      end

      response '404', 'notification not found' do
        let(:id) { 0 }
        run_test!
      end
    end
  end
end
