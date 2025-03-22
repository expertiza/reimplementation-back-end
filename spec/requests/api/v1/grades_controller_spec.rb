require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe Api::V1::GradesController, type: :controller do
    before(:all) do
      @roles = create_roles_hierarchy
    end
  
    let!(:ta) do
      User.create!(
        name: "ta",
        password_digest: "password",
        role_id: @roles[:ta].id,
        full_name: "name",
        email: "ta@example.com"
      )
    end

    let(:s1) do
        User.create(
        name: "studenta",
        password_digest: "password",
        role_id: @roles[:student].id,
        full_name: "student A",
        email: "testuser@example.com"
        )
    end

    let(:ta_token) { JsonWebToken.encode({id: ta.id}) }
    let(:student_token) { JsonWebToken.encode({id: s1.id}) }

    describe '#action_allowed' do
        context 'when the user is a Teaching Assistant' do
            it 'allows access to view_team to a TA' do
                request.headers['Authorization'] = "Bearer #{ta_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_team' }

                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => true })
            end
        end
        
        context 'when the user is a Student' do
            it 'allows access to view_team if student is viewing their own team' do    
                allow_any_instance_of(Api::V1::GradesController).to receive(:student_viewing_own_team?).and_return(true)
                allow_any_instance_of(Api::V1::GradesController).to receive(:student_or_ta?).and_return(true)

                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_team' }

                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => true })
            end

            it 'denies access to view_team if student is not viewing their own team' do
                allow_any_instance_of(Api::V1::GradesController).to receive(:student_viewing_own_team?).and_return(false)

                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_team' }

                expect(response).to have_http_status(:forbidden)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => false })
            end

            it 'allows access to view_my_scores if student has finished self review and has proper authorizations' do
                allow_any_instance_of(Api::V1::GradesController).to receive(:self_review_finished?).and_return(true)
                allow_any_instance_of(Api::V1::GradesController).to receive(:are_needed_authorizations_present?).and_return(true)
                
                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_my_scores' }

                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => true })
            end

            it 'denies access to view_my_scores if student has not finished self review or lacks authorizations' do
                allow_any_instance_of(Api::V1::GradesController).to receive(:self_review_finished?).and_return(false)

                request.headers['Authorization'] = "Bearer #{student_token}"
                request.headers['Content-Type'] = 'application/json'
                get :action_allowed, params: { requested_action: 'view_my_scores' }

                expect(response).to have_http_status(:forbidden)
                expect(JSON.parse(response.body)).to eq({ 'allowed' => false })
            end
        end
    end
end
