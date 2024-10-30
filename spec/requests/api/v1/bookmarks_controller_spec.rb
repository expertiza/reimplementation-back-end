require 'rails_helper'
require 'factory_bot_rails' # shouldn't be needed

RSpec.describe 'api/v1/bookmarks', type: :request do

  before do
    # Set the default host to localhost
    host! 'localhost'
  end

  describe User do 
    before(:each) do
      # Create a student
      @student = create(:user, role_id: Role.find_by(name: 'Student').id)
      @student_headers = authenticated_header(@student)
    end
    describe 'GET /api/v1/bookmarks' do
      it 'lets the student access the list of bookmarks' do
        get '/api/v1/bookmarks', headers: @student_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe Ta do
    before(:each) do
      # Create a teaching assistant
      @ta = create(:user, role_id: Role.find_by(name: 'Teaching Assistant').id)
      @ta_headers = authenticated_header(@ta)
    end
    describe 'GET /api/v1/bookmarks' do
      it 'lets the teaching assistant access the list of bookmarks' do
        get '/api/v1/bookmarks', headers: @ta_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe Instructor do
    before(:each) do
      # Create an instructor
      @instructor = create(:user, role_id: Role.find_by(name: 'Instructor').id)
      @instructor_headers = authenticated_header(@instructor)
    end
    describe 'GET /api/v1/bookmarks' do
      it 'lets the instructor access the list of bookmarks' do
        get '/api/v1/bookmarks', headers: @instructor_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe Administrator do
    before(:each) do
      # Create an administrator
      @admin = create(:user, role_id: Role.find_by(name: 'Administrator').id)
      @admin_headers = authenticated_header(@admin)
    end
    describe 'GET /api/v1/bookmarks' do
      it 'lets the administrator access the list of bookmarks' do
        get '/api/v1/bookmarks', headers: @admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe SuperAdministrator do
    before(:each) do
      # Create a super administrator
      @super_admin = create(:user, role_id: Role.find_by(name: 'Super Administrator').id)
      @super_admin_headers = authenticated_header(@super_admin)
    end
    describe 'GET /api/v1/bookmarks' do
      it 'lets the super administrator access the list of bookmarks' do
        get '/api/v1/bookmarks', headers: @super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  describe 'user that has not signed in' do
    describe 'GET /api/v1/bookmarks' do
      it 'does not let someone without a token access the list of bookmarks' do
        get '/api/v1/bookmarks'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
