require 'swagger_helper'
require 'rails_helper'

def auth_token_header(user)
  post '/login', params: { user_name: user.name, password: 'password' }
  { Authorization: "Bearer #{JSON.parse(response.body)['token']}" }
end

RSpec.describe 'Suggestions API', type: :request do
  let(:instructor) { instance_double(User, id: 6, role: 'instructor') }
  let(:student) { instance_double(User, id: 1, name: 'student_user', role: 'student', password: 'password') }
  let(:assignment) { instance_double(Assignment, id: 1, instructor:) }
  let(:suggestion) do
    instance_double(Suggestion, id: 1, assignment_id: assignment.id, user_id: student.id, title: 'Test Title')
  end
  let(:suggestion_comment) { instance_double(SuggestionComment) }

  def stub_current_user(user)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return({ user_id: user.id })
  end

  before(:each) do
    allow(Assignment).to receive(:find).with(assignment.id.to_s).and_return(assignment)
    allow(Suggestion).to receive(:find).with(suggestion.id.to_s).and_return(suggestion)
    stub_current_user(student)
  end

  describe '#show' do
    context 'when user is authorized' do
      it 'returns suggestion details and comments' do
        student_institution = Institution.create!(name: 'North Carolina State University')
        student_role = Role.create!(name: 'Student')
        student_user = User.create!(name: 'student_user', password: 'password', email: 'example@gmail.com',
                                    full_name: 'Student User', role: student_role, institution: student_institution)
        student_suggestion = Suggestion.create!(title: 'Sample suggestion', description: 'Sample Text',
                                                status: 'Initialized', auto_signup: false, user_id: student_user)

        get "/api/v1/suggestions/#{student_suggestion.id}", headers: auth_token_header(student_user)
        expect(response).to have_http_status(:ok)

        parsed_response = JSON.parse(response.body)
        puts parsed_response
        expect(parsed_response['suggestion']['id']).to eq(student_suggestion.id)
        expect(parsed_response['comments']).to be_an(Array)
      end
    end

    context 'when user is unauthorized' do
      it 'returns a forbidden error' do
        stub_current_user(instance_double(User, id: 2, role: 'student'))

        get "/api/v1/suggestions/#{suggestion.id}"
        expect(response).to have_http_status(:forbidden)

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['error']).to eq('Students can only view their own suggestions.')
      end
    end
  end

  describe '#add_comment' do
    it 'adds a comment and returns the comment JSON' do
      allow(SuggestionComment).to receive(:create!).and_return(suggestion_comment)
      allow(suggestion_comment).to receive(:as_json).and_return({ comment: 'Test comment' })

      stub_current_user(student, 'student', student.role)

      post "/api/v1/suggestions/#{suggestion.id}/comments", params: { comment: 'Test comment' }
      expect(response).to have_http_status(:ok)

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['comment']).to eq('Test comment')
    end

    it 'returns an error when comment creation fails' do
      allow(SuggestionComment).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(suggestion_comment))

      stub_current_user(student, 'student', student.role)

      post "/api/v1/suggestions/#{suggestion.id}/comments", params: { comment: '' }
      expect(response).to have_http_status(:unprocessable_entity)

      parsed_response = JSON.parse(response.body)
      expect(parsed_response).to include('errors')
    end
  end

  describe '#approve' do
    context 'when user is authorized' do
      it 'approves the suggestion and returns the updated suggestion JSON' do
        allow(suggestion).to receive(:update_attribute).with('status', 'Approved').and_return(true)

        stub_current_user(instructor, 'instructor', instructor.role)

        post "/api/v1/suggestions/#{suggestion.id}/approve"
        expect(response).to have_http_status(:ok)

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['status']).to eq('Approved')
      end
    end

    context 'when user is unauthorized' do
      it 'returns a forbidden error' do
        stub_current_user(student, 'student', student.role)

        post "/api/v1/suggestions/#{suggestion.id}/approve"
        expect(response).to have_http_status(:forbidden)

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['error']).to eq('Students cannot approve a suggestion.')
      end
    end
  end

  describe '#reject' do
    context 'when user is authorized' do
      it 'rejects the suggestion and returns the updated suggestion JSON' do
        allow(suggestion).to receive(:update_attribute).with('status', 'Rejected').and_return(true)

        stub_current_user(instructor, 'instructor', instructor.role)

        post "/api/v1/suggestions/#{suggestion.id}/reject"
        expect(response).to have_http_status(:ok)

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['status']).to eq('Rejected')
      end
    end

    context 'when user is unauthorized' do
      it 'returns a forbidden error' do
        stub_current_user(student, 'student', student.role)

        post "/api/v1/suggestions/#{suggestion.id}/reject"
        expect(response).to have_http_status(:forbidden)

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['error']).to eq('Students cannot reject a suggestion.')
      end
    end
  end
end
