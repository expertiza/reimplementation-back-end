require 'rails_helper'

RSpec.describe Api::V1::StudentQuizzesController, type: :controller do
  let(:student) { create(:student) }       # Creates a student user
  let(:instructor) { create(:instructor) } # Creates an instructor user
  let(:auth_token) { 'mocked_auth_token' } # mock a token
  let(:questionnaire) do # mock questionnaires
    course = create(:course, instructor: instructor)
    assignment = create(:assignment, course: course, instructor: instructor)
    create(:questionnaire, assignment: assignment, instructor: instructor)
  end

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
      assignment = create(:assignment, course: course, instructor: instructor)
      # The 3 below refers to how many quizzes you want to create. In this case we create 3 and make sure
      # the index returns a count of 3.
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

  describe 'GET #show' do
    before do
      get :show, params: { id: questionnaire.id }
    end

    it 'returns a success response' do
      expect(response).to be_successful
    end

    it 'returns the requested questionnaire data' do
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(questionnaire.id)
    end
  end

end
