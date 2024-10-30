require 'rails_helper'
require 'factory_bot_rails' # shouldn't be needed

RSpec.describe 'api/v1/bookmarks', type: :request do
  # Find each user in the users table
  # We can look it up by the role_id
  let(:student) { User.find_by(name: 'student') }
  let(:ta) { User.find_by(name: 'ta') }
  let(:instructor) { User.find_by(name: 'instructor') }
  let(:admin) { User.find_by(name: 'admin') }
  let(:super_admin) { User.find_by(name: 'super_admin') }

  # Create headers for each user so they can sign in
  let(:student_headers) { authenticated_header(student) }
  let(:ta_headers) { authenticated_header(ta) }
  let(:instructor_headers) { authenticated_header(instructor) }
  let(:admin_headers) { authenticated_header(admin) }
  let(:super_admin_headers) { authenticated_header(super_admin) }

  before do
    # Set the default host to localhost
    host! 'localhost'
  end
  
  describe 'GET /api/v1/bookmarks' do
    it 'lets the student access the list of bookmarks' do
      get '/api/v1/bookmarks', headers: student_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'lets the ta access the list of bookmarks' do
      get '/api/v1/bookmarks', headers: ta_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'lets the instructor access the list of bookmarks' do
      get '/api/v1/bookmarks', headers: instructor_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'lets the admin access the list of bookmarks' do
      get '/api/v1/bookmarks', headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'lets the super admin access the list of bookmarks' do
      get '/api/v1/bookmarks', headers: super_admin_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'does not let someone without a token access the list of bookmarks' do
      get '/api/v1/bookmarks'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
