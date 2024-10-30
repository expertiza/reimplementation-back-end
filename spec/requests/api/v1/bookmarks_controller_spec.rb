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
    # index
    describe 'GET /api/v1/bookmarks' do
      it 'lets students access empty lists of bookmarks' do
        get '/api/v1/bookmarks', headers: @student_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
      it 'lets students access lists of bookmarks' do
        bookmark = create_bookmark(@student)
        get '/api/v1/bookmarks', headers: @student_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse([bookmark].to_json))
      end
    end
    # show
    describe 'GET /api/v1/bookmarks/:id' do
      it 'allows the student to query a bookmark that does not exist' do
        get '/api/v1/bookmarks/1', headers: @student_headers
        expect(response).to have_http_status(:not_found)
      end
      it 'allows the student to query a bookmark that exists' do
        bookmark = create_bookmark(@student)
        get "/api/v1/bookmarks/#{bookmark.id}", headers: @student_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse(bookmark.to_json))
      end
    end
    # post
    describe 'POST /api/v1/bookmarks' do
      it 'lets the student create a bookmark' do
        # Prepare the bookmark
        bookmark = prepare_bookmark

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @student_headers
        expect(response).to have_http_status(:created)

        # Check that the bookmark was added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_truthy
      end
      it 'does not let the student create a bookmark with invalid parameters' do
        # Create a bookmark, but don't add it to the database
        bookmark = build(:bookmark, user_id: nil, topic_id: nil)

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @student_headers
        expect(response).to have_http_status(:unprocessable_entity)

        # Check that the bookmark was not added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
    end
    # PUT
    describe 'PUT /api/v1/bookmarks/:id' do
      it 'lets the student update their own bookmark' do
        # Prepare the bookmark
        bookmark = create_bookmark(@student)

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @student_headers
        expect(response).to have_http_status(:ok)

        # Check that the bookmark was updated in the database
        expect(Bookmark.find_by(url: 'https://www.google.com', title: 'Google', description: 'Search Engine')).to be_truthy
      end
      it 'does not let the student update a bookmark with invalid parameters' do
        # Prepare the bookmark
        bookmark = create_bookmark(@student)

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: nil, title: nil, description: nil } }, headers: @student_headers
        expect(response).to have_http_status(:unprocessable_entity)

        # Check that the bookmark was not updated in the database
        expect(Bookmark.find_by(url: nil, title: nil, description: nil)).to be_nil
      end
      it 'does not let the student update a bookmark that belongs to another student' do
        # Create another student and their bookmark
        another_student = create(:user, role_id: Role.find_by(name: 'Student').id)
        bookmark = create_bookmark(@another_student)

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @student_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was not updated in the database
        expect(Bookmark.find_by(url: 'https://www.google.com', title: 'Google', description: 'Search Engine')).to be_nil
      end
      it 'does not let the student update a bookmark that does not exist' do
        put '/api/v1/bookmarks/1', params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @student_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe Ta do
    before(:each) do
      # Create a teaching assistant
      @ta = create(:user, role_id: Role.find_by(name: 'Teaching Assistant').id)
      @ta_headers = authenticated_header(@ta)
    end
    # index
    describe 'GET /api/v1/bookmarks' do
      it 'lets the teaching assistant access empty lists of bookmarks' do
        get '/api/v1/bookmarks', headers: @ta_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
      it 'lets the teaching assistant access lists of bookmarks' do
        bookmark = create_bookmark
        get '/api/v1/bookmarks', headers: @ta_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse([bookmark].to_json))
      end
    end
    # show
    describe 'GET /api/v1/bookmarks/:id' do
      it 'allows the teaching assistant to query a bookmark that does not exist' do
        get '/api/v1/bookmarks/1', headers: @ta_headers
        expect(response).to have_http_status(:not_found)
      end
      it 'allows the teaching assistant to query a bookmark that exists' do
        bookmark = create_bookmark
        get "/api/v1/bookmarks/#{bookmark.id}", headers: @ta_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse(bookmark.to_json))
      end
    end
    # post
    describe 'POST /api/v1/bookmarks' do
      it 'does not let the teaching assistant create a bookmark' do
        # Prepare the bookmark
        bookmark = prepare_bookmark

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @ta_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
      it 'does not let the teaching assistant create a bookmark with invalid parameters' do
        # Create a bookmark, but don't add it to the database
        bookmark = build(:bookmark, user_id: nil, topic_id: nil)

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @ta_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was not added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
    end
    # PUT
    # Temporarily disabled while we figure out how to add TAs to classes
  end

  describe Instructor do
    before(:each) do
      # Create an instructor
      @instructor = create(:user, role_id: Role.find_by(name: 'Instructor').id)
      @instructor_headers = authenticated_header(@instructor)
    end
    # index
    describe 'GET /api/v1/bookmarks' do
      it 'lets the instructor access empty lists of bookmarks' do
        get '/api/v1/bookmarks', headers: @instructor_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
      it 'lets the instructor access lists of bookmarks' do
        bookmark = create_bookmark
        get '/api/v1/bookmarks', headers: @instructor_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse([bookmark].to_json))
      end
    end
    # show
    describe 'GET /api/v1/bookmarks/:id' do
      it 'allows the instructor to query a bookmark that does not exist' do
        get '/api/v1/bookmarks/1', headers: @instructor_headers
        expect(response).to have_http_status(:not_found)
      end
      it 'allows the instructor to query a bookmark that exists' do
        bookmark = create_bookmark
        get "/api/v1/bookmarks/#{bookmark.id}", headers: @instructor_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse(bookmark.to_json))
      end
    end
    # post
    describe 'POST /api/v1/bookmarks' do
      it 'does not let the instructor create a bookmark' do
        # Prepare the bookmark
        bookmark = prepare_bookmark

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @instructor_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
      it 'does not let the instructor create a bookmark with invalid parameters' do
        # Create a bookmark, but don't add it to the database
        bookmark = build(:bookmark, user_id: nil, topic_id: nil)

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @instructor_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was not added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
    end
    # PUT
    describe 'PUT /api/v1/bookmarks/:id' do
      it 'lets the instructor update a bookmark for their own assignment' do
        # Prepare the bookmark
        bookmark = create_bookmark

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @instructor_headers
        expect(response).to have_http_status(:ok)

        # Check that the bookmark was updated in the database
        expect(Bookmark.find_by(url: 'https://www.google.com', title: 'Google', description: 'Search Engine')).to be_truthy
      end
      it 'does not let the instructor update a bookmark with invalid parameters' do
        # Prepare the bookmark
        bookmark = create_bookmark

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: nil, title: nil, description: nil } }, headers: @instructor_headers
        expect(response).to have_http_status(:unprocessable_entity)

        # Check that the bookmark was not updated in the database
        expect(Bookmark.find_by(url: nil, title: nil, description: nil)).to be_nil
      end
      it 'does not let the instructor update a bookmark that does not exist' do
        put '/api/v1/bookmarks/1', params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @instructor_headers
        expect(response).to have_http_status(:not_found)
      end
      it 'does not let the instructor update a bookmark for another instructors assignment' do
        # Create another instructor and their bookmark
        bookmark = create_bookmark
        # Create another instructor
        another_instructor = create(:user, role_id: Role.find_by(name: 'Instructor').id)
        another_instructor_headers = authenticated_header(another_instructor)

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: another_instructor_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was not updated in the database
        expect(Bookmark.find_by(url: 'https://www.google.com', title: 'Google', description: 'Search Engine')).to be_nil
      end
    end
  end

  describe Administrator do
    before(:each) do
      # Create an administrator
      @admin = create(:user, role_id: Role.find_by(name: 'Administrator').id)
      @admin_headers = authenticated_header(@admin)
    end
    # index
    describe 'GET /api/v1/bookmarks' do
      it 'lets the administrator access empty lists of bookmarks' do
        get '/api/v1/bookmarks', headers: @admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
      it 'lets the administrator access lists of bookmarks' do
        bookmark = create_bookmark
        get '/api/v1/bookmarks', headers: @admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse([bookmark].to_json))
      end
    end
    # show
    describe 'GET /api/v1/bookmarks/:id' do
      it 'allows the administrator to query a bookmark that does not exist' do
        get '/api/v1/bookmarks/1', headers: @admin_headers
        expect(response).to have_http_status(:not_found)
      end
      it 'allows the administrator to query a bookmark that exists' do
        bookmark = create_bookmark
        get "/api/v1/bookmarks/#{bookmark.id}", headers: @admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse(bookmark.to_json))
      end
    end
    # post
    describe 'POST /api/v1/bookmarks' do
      it 'does not let the administrator create a bookmark' do
        # Prepare the bookmark
        bookmark = prepare_bookmark

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @admin_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
      it 'does not let the administrator create a bookmark with invalid parameters' do
        # Create a bookmark, but don't add it to the database
        bookmark = build(:bookmark, user_id: nil, topic_id: nil)

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @admin_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was not added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
    end
    # PUT
    describe 'PUT /api/v1/bookmarks/:id' do
      it 'lets the administrator update a bookmark if they are the parent of the instructor who created the assignment' do
        # Create the bookmark
        bookmark = create_bookmark
        # Find the instructor
        instructor = User.find(bookmark.topic.assignment.course.instructor_id)
        # Make the administrator the parent of the instructor
        instructor.parent_id = @admin.id
        instructor.save

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @admin_headers
        expect(response).to have_http_status(:ok)

        # Check that the bookmark was updated in the database
        expect(Bookmark.find_by(url: 'https://www.google.com', title: 'Google', description: 'Search Engine')).to be_truthy
      end
      it 'does not let the administrator update a bookmark if they are not the parent of the instructor who created the assignment' do
        # Create the bookmark
        bookmark = create_bookmark
        # The administrator is not the parent of the instructor at this point

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @admin_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was not updated in the database
        expect(Bookmark.find_by(url: 'https://www.google.com', title: 'Google', description: 'Search Engine')).to be_nil
      end
      it 'does not let the administrator update a bookmark with invalid parameters' do
        # Create the bookmark
        bookmark = create_bookmark
        # Find the instructor
        instructor = User.find(bookmark.topic.assignment.course.instructor_id)
        # Make the administrator the parent of the instructor
        instructor.parent_id = @admin.id
        instructor.save

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: nil, title: nil, description: nil } }, headers: @admin_headers
        expect(response).to have_http_status(:unprocessable_entity)

        # Check that the bookmark was not updated in the database
        expect(Bookmark.find_by(url: nil, title: nil, description: nil)).to be_nil
      end
      it 'does not let the administrator update a bookmark that does not exist' do
        put '/api/v1/bookmarks/1', params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @admin_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe SuperAdministrator do
    before(:each) do
      # Create a super administrator
      @super_admin = create(:user, role_id: Role.find_by(name: 'Super Administrator').id)
      @super_admin_headers = authenticated_header(@super_admin)
    end
    # index
    describe 'GET /api/v1/bookmarks' do
      it 'lets the super administrator access empty lists of bookmarks' do
        get '/api/v1/bookmarks', headers: @super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
      it 'lets the super administrator access lists of bookmarks' do
        bookmark = create_bookmark
        get '/api/v1/bookmarks', headers: @super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse([bookmark].to_json))
      end
    end
    # show
    describe 'GET /api/v1/bookmarks/:id' do
      it 'allows the super administrator to query a bookmark that does not exist' do
        get '/api/v1/bookmarks/1', headers: @super_admin_headers
        expect(response).to have_http_status(:not_found)
      end
      it 'allows the super administrator to query a bookmark that exists' do
        bookmark = create_bookmark
        get "/api/v1/bookmarks/#{bookmark.id}", headers: @super_admin_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(JSON.parse(bookmark.to_json))
      end
    end
    # post
    describe 'POST /api/v1/bookmarks' do
      it 'does not let the super administrator create a bookmark' do
        # Prepare the bookmark
        bookmark = prepare_bookmark

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @super_admin_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
      it 'does not let the super administrator create a bookmark with invalid parameters' do
        # Create a bookmark, but don't add it to the database
        bookmark = build(:bookmark, user_id: nil, topic_id: nil)

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }, headers: @super_admin_headers
        expect(response).to have_http_status(:forbidden)

        # Check that the bookmark was not added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end        
    end
    # PUT
    describe 'PUT /api/v1/bookmarks/:id' do
      it 'lets the super administrator update a bookmark' do
        # Prepare the bookmark
        bookmark = create_bookmark

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @super_admin_headers
        expect(response).to have_http_status(:ok)

        # Check that the bookmark was updated in the database
        expect(Bookmark.find_by(url: 'https://www.google.com', title: 'Google', description: 'Search Engine')).to be_truthy
      end
      it 'does not let the super administrator update a bookmark with invalid parameters' do
        # Prepare the bookmark
        bookmark = create_bookmark

        # Update the bookmark
        put "/api/v1/bookmarks/#{bookmark.id}", params: { bookmark: { url: nil, title: nil, description: nil } }, headers: @super_admin_headers
        expect(response).to have_http_status(:unprocessable_entity)

        # Check that the bookmark was not updated in the database
        expect(Bookmark.find_by(url: nil, title: nil, description: nil)).to be_nil
      end
      it 'does not let the super administrator update a bookmark that does not exist' do
        put '/api/v1/bookmarks/1', params: { bookmark: { url: 'https://www.google.com', title: 'Google', description: 'Search Engine' } }, headers: @super_admin_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'user that has not signed in' do
    http_unauthorized = 401
    # index
    describe 'GET /api/v1/bookmarks' do
      it 'does not let users who are not signed in access empty lists of bookmarks' do
        get '/api/v1/bookmarks'
        expect(response).to have_http_status(http_unauthorized)
        expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
      end
      it 'does not let users who are not signed in access lists of bookmarks' do
        bookmark = create_bookmark
        get '/api/v1/bookmarks'
        expect(response).to have_http_status(http_unauthorized)
        expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
      end
    end
    # show
    describe 'GET /api/v1/bookmarks/:id' do
      it 'does not allow users who are not signed in to query a bookmark that does not exist' do
        get '/api/v1/bookmarks/1'
        expect(response).to have_http_status(http_unauthorized)
        expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
      end
      it 'does not allow users who are not signed in to query a bookmark that exists' do
        bookmark = create_bookmark
        get "/api/v1/bookmarks/#{bookmark.id}"
        expect(response).to have_http_status(http_unauthorized)
        expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
      end
    end
    # post
    describe 'POST /api/v1/bookmarks' do
      it 'does not let users who are not signed in to create a bookmark' do
        # Prepare the bookmark
        bookmark = prepare_bookmark

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }
        expect(response).to have_http_status(http_unauthorized)

        # Check that the bookmark was added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
      it 'does not let users who are not signed in to create a bookmark with invalid parameters' do
        # Create a bookmark, but don't add it to the database
        bookmark = build(:bookmark, user_id: nil, topic_id: nil)

        # Now add the bookmark to the database
        post '/api/v1/bookmarks', params: { bookmark: { url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id } }
        expect(response).to have_http_status(http_unauthorized)

        # Check that the bookmark was not added to the database
        expect(Bookmark.find_by(url: bookmark.url, title: bookmark.title, description: bookmark.description, topic_id: bookmark.topic_id)).to be_nil
      end
    end
  end
end

def prepare_bookmark(user = nil)
  # Look for an instructor
  instructor = User.find_by(role: Role.find_by(name: 'Instructor'))
  # Create an instructor if it does not exist
  instructor = create(:user, role_id: Role.find_by(name: 'Instructor').id) if instructor.nil?
  
  # Look for a course
  course = Course.find_by(instructor_id: instructor.id)
  # Create a course if it does not exist
  course = create(:course, instructor_id: instructor.id) if course.nil?
  
  # Look for an assignment
  assignment = Assignment.find_by(course_id: course.id)
  # Create an assignment if it does not exist
  assignment = create(:assignment, course_id: course.id) if assignment.nil?
  
  # Look for a topic
  topic = SignUpTopic.find_by(assignment_id: assignment.id)
  # Create a topic if it does not exist
  topic = create(:sign_up_topic, assignment_id: assignment.id) if topic.nil?
  
  # If user is nil, make a new student
  user = create(:user, role_id: Role.find_by(name: 'Student').id) if user.nil?

  bookmark = build(:bookmark, user_id: user.id, topic_id: topic.id)

  # Return the bookmark
  bookmark
end

def create_bookmark(user = nil)
  # Prepare the bookmark
  bookmark = prepare_bookmark(user)
  # Save the bookmark
  bookmark.save!
  # Return the bookmark
  bookmark
end
