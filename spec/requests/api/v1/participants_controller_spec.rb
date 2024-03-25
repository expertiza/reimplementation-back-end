require 'rails_helper'

RSpec.describe Api::V1::ParticipantsController, type: :request do
  before(:each) do
    @user = User.create!( username: 'testuser',
                           email: 'test@example.com',
                           password: 'password123',
                           role_id: 2)
    @course = Course.create!(
      name: 'Intro to Testing',
      subject: 'Software Engineering'
    )
    @assignment = Assignment.create!(name: 'Test Assignment',
                                     course_id: @course.id,
                                     instructor_id: @user.id,
                                     description: 'This is a test assignment.')
  end

  describe 'POST /api/v1/participants' do
    context 'when the user and assignment exist' do
      let(:valid_attributes) do
        {
          participant: {
            user_id: @user.id,
            assignment_id: @assignment.id
          }
        }
      end

      it 'creates a new Participant' do
        expect {
          post '/api/v1/participants', params: valid_attributes
        }.to change(Participant, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'when the user does not exist' do
      let(:invalid_attributes) do
        {
          participant: {
            user_id: nil,
            assignment_id: @assignment.id
          }
        }
      end

      it 'does not create a participant and returns a not found status' do
        expect {
          post '/api/v1/participants', params: invalid_attributes
        }.not_to change(Participant, :count)

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('User does not exist')
      end
    end

    context 'when the assignment does not exist' do
      let(:invalid_attributes) do
        {
          participant: {
            user_id: @user.id,
            assignment_id: nil
          }
        }
      end

      it 'does not create a participant and returns a not found status' do
        expect {
          post '/api/v1/participants', params: invalid_attributes
        }.not_to change(Participant, :count)

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('Assignment does not exist')
      end
    end
  end

  after(:each) do
    User.delete_all
    Assignment.delete_all
  end
end
