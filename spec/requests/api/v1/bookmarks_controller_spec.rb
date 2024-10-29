require 'rails_helper'
RSpec.describe 'api/v1/bookmarks', type: :request do
  let(:user) { User.create(email: 'test@test.com', password: 'password') }
  let(:user_headers) { authenticated_header(user) }
  let(:admin_headers) { authenticated_header }

  before do
    # Set the default host to localhost
    host! 'localhost'
  end
  
  describe 'GET /api/v1/bookmarks' do
    it 'does not let the user access the list of bookmarks' do
      get '/api/v1/bookmarks', headers: user_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'lets the admin access the list of bookmarks' do
      get '/api/v1/bookmarks', headers: admin_headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end
end
