require 'rails_helper'

RSpec.describe Api::V1::StudentQuizzesController, type: :controller do
  let(:student) { create(:student) }       # Creates a student user
  let(:instructor) { create(:instructor) } # Creates an instructor user
  let(:auth_token) { 'mocked_auth_token' } # mock a token

  before do
    allow_any_instance_of(Api::V1::StudentQuizzesController)
      .to receive(:authenticate_request!)
            .and_return(true)

    allow_any_instance_of(Api::V1::StudentQuizzesController)
      .to receive(:current_user)
            .and_return(instructor)

    request.headers['Authorization'] = "Bearer #{auth_token}"
  end

  describe 'GET #index' do
    before do
      create(:institution)
      course = create(:course, instructor: instructor)
      puts "Instructor role_id: #{instructor.role_id}"  # Debugging output
      assignment = create(:assignment, course: course, instructor: instructor)
      create_list(:questionnaire, 3, assignment: assignment)

      get :index
    end

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'returns all quizzes' do
      json_response = JSON.parse(response.body)
      expect(json_response.count).to eq(3)
    end
  end

  # Additional tests for other actions can be added here...
end
